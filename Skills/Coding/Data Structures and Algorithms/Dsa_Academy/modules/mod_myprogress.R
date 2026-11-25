# modules/mod_myprogress.R — persistent progress dashboard: solved, streaks, time, weak topics, reviews.

myprogress_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("📈", "My Progress",
      "Everything you do is saved in Google BigQuery (APIs › BigQuery): every run and submission, time on task, quiz scores and mock interviews. Use it to find weak topics and to keep solved problems fresh with spaced reviews.",
      c("Saved in BigQuery", "Spaced reviews 3 → 7 → 21 days", "Weak-topic finder", "Activity heatmap")),
    uiOutput(ns("kpis")),
    fluidRow(
      box(title = "🔁 Due for review", status = "warning", solidHeader = TRUE, width = 5,
        uiOutput(ns("due")),
        hint(sprintf("A problem enters the review cycle when you first get Accepted. Solving it again when due moves it to the next gap (%s days), then it counts as mastered. A failed review comes back tomorrow.",
                     paste(REVIEW_GAPS, collapse = " → ")))),
      box(title = "🎯 Weakest topics — and what to do next", status = "danger", solidHeader = TRUE, width = 7,
        plotlyOutput(ns("weak_plot"), height = "270px"),
        uiOutput(ns("weak_next")))
    ),
    fluidRow(
      box(title = "Activity — last 16 weeks", status = "info", solidHeader = TRUE, width = 7, plotlyOutput(ns("heat"), height = "230px")),
      box(title = "Solved by difficulty and company", status = "info", solidHeader = TRUE, width = 5, plotlyOutput(ns("by_diff"), height = "230px"))
    ),
    fluidRow(
      box(title = "Time on task by topic", status = "info", solidHeader = TRUE, width = 5, plotlyOutput(ns("time_topic"), height = "300px")),
      box(title = "Quiz mastery (best saved score per topic)", status = "info", solidHeader = TRUE, width = 7, plotlyOutput(ns("quiz_plot"), height = "300px"))
    ),
    fluidRow(
      box(title = "Interview skills beyond algorithms", status = "info", solidHeader = TRUE, width = 12,
        hint("AI-assisted projects, code reading, behavioural answers and design mocks are saved too. Open each page for details."),
        uiOutput(ns("skills")))
    ),
    fluidRow(
      box(title = "All problems", status = "primary", solidHeader = TRUE, width = 12, DTOutput(ns("problems")))
    ),
    fluidRow(
      box(title = "Submission history", status = "primary", solidHeader = TRUE, width = 8, DTOutput(ns("history"))),
      box(title = "Your data", status = "primary", solidHeader = TRUE, width = 4,
        uiOutput(ns("data_loc")),
        downloadButton(ns("export"), "Export submissions (CSV)", class = "btn btn-dsa-outline btn-sm"),
        tags$br(), tags$br(),
        actionButton(ns("reset"), "Delete all progress…", class = "btn btn-dsa-outline btn-sm"))
    )
  )
}

myprogress_server <- function(id, progress = NULL, bus) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    status <- reactive({ bus$db_tick; db_problem_status() })
    subs   <- reactive({ bus$db_tick; db_submissions() })
    act    <- reactive({ bus$db_tick; db_activity() })
    quiz   <- reactive({ bus$db_tick; db_quiz_best() })
    ivs    <- reactive({ bus$db_tick; db_interviews() })

    solve_btn <- function(pid, label = "Solve") as.character(tags$button(class = "btn btn-dsa btn-xs-solve", onclick = js_set("open_problem", sprintf("'%s'", pid)), label))

    output$skills <- renderUI({
      bus$db_tick; input$reset
      pa <- db_table("project_attempts"); ra <- db_table("reading_attempts"); ba <- db_table("behav_attempts"); da <- db_table("design_attempts")
      st <- db_table("star_stories")
      sub <- pa[pa$mode == "submit", , drop = FALSE]
      solved <- length(unique(sub$project_id[sub$passed == sub$total & sub$total > 0]))
      aud <- pa[pa$mode == "audit", , drop = FALSE]
      first <- ra[!duplicated(ra$ex_id, fromLast = TRUE), , drop = FALSE]
      covered <- length(unique(unlist(strsplit(paste(st$competencies, collapse = " | "), " \\| "))))
      covered <- covered - ("" %in% unlist(strsplit(paste(st$competencies, collapse = " | "), " \\| ")))
      kpi_row(
        kpi(sprintf("%d / %d", solved, length(PROJECTS)), "AI-round projects passed", COL$ok),
        kpi(if (nrow(aud)) sprintf("%.0f%%", 100 * mean(aud$caught_ai == 1, na.rm = TRUE)) else "—", "audits that caught the AI", COL$warn),
        kpi(sprintf("%d / %d", length(unique(ra$ex_id[ra$correct == 1])), length(READING)), "code-reading solved", COL$pri),
        kpi(if (nrow(first)) sprintf("%.0f%%", 100 * mean(first$correct == 1)) else "—", "reading accuracy", COL$acc),
        kpi(sprintf("%d · %d/%d", nrow(st), max(0, covered), length(COMPETENCIES)), "STAR stories · competencies", COL$sec),
        kpi(if (nrow(ba)) sprintf("%.0f%%", mean(ba$total)) else "—", sprintf("behavioural avg (%d)", nrow(ba)), COL$pink),
        kpi(if (nrow(da)) sprintf("%.0f%%", mean(da$coverage)) else "—", sprintf("design coverage (%d)", nrow(da)), COL$mute))
    })

    output$kpis <- renderUI({
      s <- status(); sb <- subs(); sb <- sb[sb$mode %in% c("submit", "interview"), ]; iv <- ivs()
      acc <- if (nrow(sb)) 100 * mean(sb$verdict == "Accepted") else NA
      hrs <- sum(s$seconds) / 3600
      kpi_row(
        kpi(sprintf("%d / %d", sum(s$solved), nrow(s)), "problems solved", COL$ok),
        kpi(sum(s$attempts > 0), "attempted", COL$pri),
        kpi(if (is.na(acc)) "—" else sprintf("%.0f%%", acc), "acceptance rate", COL$acc),
        kpi(if (sum(s$solved)) sprintf("%.0f%%", 100 * sum(s$first_try) / sum(s$solved)) else "—", "solved first try", COL$sec),
        kpi(db_streak(), "day streak", COL$warn),
        kpi(if (hrs < 1) sprintf("%.0f min", hrs * 60) else sprintf("%.1f h", hrs), "time on problems", COL$pri),
        kpi(sum(s$due), "reviews due", if (sum(s$due)) COL$err else COL$ok),
        kpi(if (nrow(iv)) sprintf("%d · %.0f", nrow(iv), mean(iv$total)) else "0", "mocks · avg score", COL$acc))
    })

    output$due <- renderUI({
      s <- status()
      due <- s[s$due, ]; due <- due[order(due$next_due), ]
      up <- s[!is.na(s$next_due) & !s$due & s$next_due <= format(Sys.Date() + 14), ]; up <- up[order(up$next_due), ]
      mastered <- sum(!is.na(s$stage) & s$stage > length(REVIEW_GAPS))
      tagList(
        if (!nrow(due)) callout(if (sum(s$solved)) "Nothing due today. 🎉" else "Solve your first problem in the Workspace to start the review cycle.", "success")
        else tags$div(lapply(seq_len(nrow(due)), function(i) tags$div(class = "due-row",
          lc_badge(due$difficulty[i]), tags$span(class = "due-title", sprintf("%d. %s", due$num[i], due$title[i])),
          tags$span(class = "hint", style = "margin:0;", sprintf("review %d · due %s", due$stage[i], due$next_due[i])),
          HTML(solve_btn(due$id[i], "Review"))))),
        if (nrow(up)) tagList(tags$div(class = "code-title", "Coming up in the next two weeks"),
          tags$div(class = "lane", lapply(seq_len(nrow(up)), function(i) tags$span(class = "vnode sm visited", title = up$title[i], sprintf("#%d · %s", up$num[i], format(as.Date(up$next_due[i]), "%b %d")))))),
        tags$div(class = "hint", style = "margin-top:8px;", sprintf("%d problem(s) mastered (passed every review).", mastered)))
    })

    weak <- reactive({
      s <- status(); q <- quiz()
      topics <- names(TOPICS)
      rows <- lapply(topics, function(t) {
        st <- s[s$topic == t, ]
        att <- sum(st$attempts > 0); sol <- sum(st$solved)
        parts <- c(practice = if (att) 100 * sol / att else NA,
                   first = if (sol) 100 * sum(st$first_try) / sol else NA,
                   quiz = if (t %in% q$topic) 100 * q$best[q$topic == t] else NA)
        data.frame(topic = t, label = TOPICS[[t]], score = if (all(is.na(parts))) NA else mean(parts, na.rm = TRUE),
                   attempted = att, solved = sol, bank = nrow(st), quiz = parts[["quiz"]], stringsAsFactors = FALSE)
      })
      do.call(rbind, rows)
    })
    output$weak_plot <- renderPlotly({
      w <- weak(); w <- w[!is.na(w$score), ]
      validate(need(nrow(w) > 0, "Weak topics appear once you have submitted solutions or completed a topic quiz."))
      w <- w[order(w$score), ]
      cols <- ifelse(w$score < 50, COL$err, ifelse(w$score < 75, COL$warn, COL$ok))
      plot_ly(y = factor(w$label, levels = rev(w$label)), x = w$score, type = "bar", orientation = "h", height = 270,
              marker = list(color = cols), text = sprintf("%.0f", w$score), textposition = "outside",
              hovertext = sprintf("%s<br>solved %d of %d attempted<br>quiz best %s", w$label, w$solved, w$attempted, ifelse(is.na(w$quiz), "—", sprintf("%.0f%%", w$quiz))), hoverinfo = "text") %>%
        dsa_layout(xt = "strength score (0–100)") %>% layout(xaxis = list(range = c(0, 115)), margin = list(l = 150))
    })
    output$weak_next <- renderUI({
      w <- weak(); s <- status()
      cand <- w[!is.na(w$score), ]; cand <- cand[order(cand$score), ]
      untouched <- w$topic[is.na(w$score) & w$bank > 0]
      focus <- head(c(cand$topic[cand$score < 80], untouched), 2)
      if (!length(focus)) return(hint("No weak spots detected yet. Keep a mix of new problems and reviews."))
      picks <- do.call(rbind, lapply(focus, function(t) {
        sub <- s[s$topic == t & !s$solved, ]
        head(sub[order(match(sub$difficulty, c("Easy", "Medium", "Hard"))), ], 2)
      }))
      tagList(
        tags$div(class = "code-title", sprintf("Suggested next: %s", paste(vapply(focus, function(t) TOPICS[[t]], ""), collapse = " and "))),
        hint("Score = average of: share of attempted problems you solved, share solved on the first submission, and your best quiz score for the topic. Topics you have not touched are listed after weak ones."),
        if (!is.null(picks) && nrow(picks)) tags$div(lapply(seq_len(nrow(picks)), function(i) tags$div(class = "due-row",
          lc_badge(picks$difficulty[i]), tags$span(class = "due-title", sprintf("%d. %s", picks$num[i], picks$title[i])),
          tags$span(class = "prob-pattern", TOPICS[[picks$topic[i]]]), HTML(solve_btn(picks$id[i]))))),
        tags$button(class = "btn btn-dsa-outline btn-sm", style = "margin-top:6px;", onclick = js_set("goto_tab", sprintf("'%s'", focus[1])), sprintf("Revise %s →", TOPICS[[focus[1]]])))
    })

    output$heat <- renderPlotly({
      a <- act()
      end <- Sys.Date(); start <- end - 7 * 16 + 1
      start <- start - (as.integer(format(start, "%u")) - 1)
      days <- seq(start, end, by = "day")
      n <- a$n[match(format(days), a$day)]; n[is.na(n)] <- 0
      mins <- round(a$seconds[match(format(days), a$day)] / 60); mins[is.na(mins)] <- 0
      wk <- as.integer((days - start) / 7) + 1; wd <- as.integer(format(days, "%u"))
      z <- matrix(NA, 7, max(wk)); txt <- matrix("", 7, max(wk))
      for (i in seq_along(days)) { z[wd[i], wk[i]] <- n[i]; txt[wd[i], wk[i]] <- sprintf("%s<br>%d runs / submissions<br>%d min on problems", format(days[i], "%a %d %b"), n[i], mins[i]) }
      plot_ly(z = z, x = format(start + 7 * (seq_len(max(wk)) - 1), "%d %b"), y = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"),
              type = "heatmap", text = txt, hoverinfo = "text", xgap = 3, ygap = 3, height = 230, showscale = FALSE,
              colorscale = list(c(0, "#eef2ff"), c(0.01, "#c7d2fe"), c(0.4, "#818cf8"), c(1, "#3730a3"))) %>%
        layout(yaxis = list(autorange = "reversed", fixedrange = TRUE), xaxis = list(fixedrange = TRUE, tickangle = 0, nticks = 8),
               margin = list(l = 40, r = 10, t = 10, b = 30), plot_bgcolor = "#ffffff", paper_bgcolor = "#ffffff") %>% config(displayModeBar = FALSE)
    })

    output$by_diff <- renderPlotly({
      s <- status(); lv <- c("Easy", "Medium", "Hard")
      solved <- vapply(lv, function(d) sum(s$solved & s$difficulty == d), numeric(1))
      tot <- vapply(lv, function(d) sum(s$difficulty == d), numeric(1))
      meta <- c(sum(s$solved & s$meta), sum(s$meta)); goo <- c(sum(s$solved & s$google), sum(s$google))
      x <- c(lv, "Meta-reported", "Google-reported")
      plot_ly(height = 230) %>%
        add_bars(x = x, y = c(solved, meta[1], goo[1]), name = "solved", marker = list(color = c(COL$ok, COL$warn, COL$err, "#0866ff", "#34a853"))) %>%
        add_bars(x = x, y = c(tot - solved, meta[2] - meta[1], goo[2] - goo[1]), name = "remaining", marker = list(color = COL$idle)) %>%
        dsa_layout(yt = "problems") %>% layout(barmode = "stack", xaxis = list(categoryorder = "array", categoryarray = x))
    })

    output$time_topic <- renderPlotly({
      s <- status(); validate(need(sum(s$seconds) > 0, "Time is recorded while you work in the Workspace (counted only while the window is active)."))
      agg <- tapply(s$seconds, s$topic, sum); agg <- sort(agg[agg > 0])
      plot_ly(y = factor(unname(TOPICS[names(agg)]), levels = unname(TOPICS[names(agg)])), x = as.numeric(agg) / 60, type = "bar", orientation = "h",
              marker = list(color = COL$pri), height = 300, text = sprintf("%.0f min", as.numeric(agg) / 60), textposition = "outside") %>%
        dsa_layout(xt = "minutes") %>% layout(margin = list(l = 150), xaxis = list(range = c(0, max(agg) / 60 * 1.25)))
    })

    output$quiz_plot <- renderPlotly({
      q <- quiz(); validate(need(nrow(q) > 0, "Complete a topic quiz (Practise tab of any topic) to see it here."))
      lab <- ifelse(q$topic %in% names(TOPICS), unname(TOPICS[q$topic]), ifelse(q$topic == "bigo", "Big-O", ifelse(q$topic == "patterns", "Pattern Finder", q$topic)))
      o <- order(q$best)
      plot_ly(y = factor(lab[o], levels = lab[o]), x = 100 * q$best[o], type = "bar", orientation = "h", height = 300,
              marker = list(color = ifelse(q$best[o] >= 0.8, COL$ok, ifelse(q$best[o] >= 0.6, COL$warn, COL$err))),
              text = sprintf("%.0f%% · %d attempt(s)", 100 * q$best[o], q$attempts[o]), textposition = "outside") %>%
        dsa_layout(xt = "best score %") %>% layout(xaxis = list(range = c(0, 135)), margin = list(l = 150))
    })

    output$problems <- renderDT({
      s <- status()
      d <- data.frame(
        ` ` = vapply(s$id, function(i) solve_btn(i), ""),
        `#` = s$num, Problem = s$title,
        Difficulty = sprintf("<span class='lc-badge badge-%s'>%s</span>", tolower(s$difficulty), s$difficulty),
        Topic = unname(TOPICS[s$topic]),
        Companies = PRACTICE_DF$companies[match(s$id, PRACTICE_DF$id)],
        Status = ifelse(s$due, "🔁 due", ifelse(s$solved, "✅ solved", ifelse(s$attempts > 0, "🟡 attempted", "—"))),
        Submissions = s$attempts,
        `Next review` = ifelse(is.na(s$next_due), ifelse(!is.na(s$stage), "mastered", ""), s$next_due),
        `Time (min)` = round(s$seconds / 60),
        check.names = FALSE, stringsAsFactors = FALSE)
      datatable(d, escape = FALSE, rownames = FALSE, selection = "none",
                options = list(pageLength = 10, dom = "ftip", columnDefs = list(list(orderable = FALSE, targets = 0))))
    })

    output$history <- renderDT({
      h <- subs(); h <- h[h$mode %in% c("run", "submit", "interview", "view"), ]
      validate(need(nrow(h) > 0, "No activity yet."))
      title <- vapply(h$problem_id, function(i) if (i %in% PRACTICE_IDS) sprintf("%d. %s", PRACTICE[[i]]$num, PRACTICE[[i]]$title) else i, "")
      datatable(data.frame(When = h$ts, Problem = title, Type = h$mode,
                           Verdict = sprintf("<span style='color:%s;font-weight:700;'>%s</span>", ifelse(h$verdict == "Accepted", "#059669", ifelse(h$mode == "view", "#64748b", "#dc2626")), h$verdict),
                           Tests = ifelse(is.na(h$total), "", paste0(h$passed, " / ", h$total))),
                escape = FALSE, rownames = FALSE, selection = "none", options = list(pageLength = 10, dom = "ftip", ordering = FALSE))
    })

    output$data_loc <- renderUI({
      bus$db_tick; invalidateLater(5000); st <- bq_state()
      if (st$ready) hint(sprintf("Saved in Google BigQuery: <code>%s</code>. %s", st$where, if (st$pending) sprintf("%d change(s) are being written now.", st$pending) else "Everything is saved."))
      else callout(sprintf("<b>Not connected to BigQuery.</b> %d change(s) are held in memory and will be written when you connect in <b>APIs › BigQuery</b>.", st$pending), "warn")
    })

    output$export <- downloadHandler(
      filename = function() sprintf("dsa_submissions_%s.csv", format(Sys.Date())),
      content = function(file) {
        s <- db_submissions_full()
        utils::write.csv(s, file, row.names = FALSE)
      })

    observeEvent(input$reset, {
      showModal(modalDialog(title = "Delete all progress?",
        "This permanently deletes every submission, draft, review schedule, quiz score, mock interview and practice-round attempt from the BigQuery tables (your STAR stories, settings and export history are kept).",
        footer = tagList(modalButton("Cancel"), actionButton(ns("reset_ok"), "Delete everything", class = "btn btn-dsa"))))
    })
    observeEvent(input$reset_ok, { removeModal(); db_reset(); bus$db_tick <- bus$db_tick + 1; showNotification("All progress deleted.", type = "warning") })
  })
}
