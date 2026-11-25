# ---- module ----------------------------------------------
# id:           section_drafts
# name:         Section drafts
# icon:         file-pen
# description:  One box per application question with a live word count; Claude drafts from the whole bid; every save is a version
# packages:     shiny, officer
# -----------------------------------------------------------
# Ported from BOS modules/Project Application/project_details.R, business_case.R and team_impact.R,
# but driven by Question sets instead of fixed CAM questions. Saved to answers (one row per version).

section_drafts_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$script(HTML("
      function cpCount(el){ var box=$(el).closest('.cp-ans'); var lim=parseInt(box.data('limit'))||0;
        var t=$.trim($(el).val()); var n=t? t.split(/\\s+/).length : 0; var wc=box.find('.wc');
        wc.text(n + (lim? ' / ' + lim : '') + ' words'); wc.toggleClass('over', lim>0 && n>lim); }
      $(document).on('input', '.cp-ans textarea', function(){ cpCount(this); });
      $(document).on('shiny:inputchanged', function(e){ var el=document.getElementById(e.name); if(el && $(el).closest('.cp-ans').length) cpCount(el); });
      $(document).on('shiny:value', function(){ setTimeout(function(){ $('.cp-ans textarea').each(function(){ cpCount(this); }); }, 50); });
    ")),
    card(NULL, layout_columns(col_widths = c(6, 6),
      selectInput(ns("proj"), "Project", NULL, width = "100%"),
      selectInput(ns("set"), "Question set", NULL, width = "100%"))),
    uiOutput(ns("summary")),
    uiOutput(ns("questions")),
    card(NULL, div(class = "btn-row",
      actionButton(ns("save_all"), "Save all", class = "btn-brand", icon = icon("floppy-disk")),
      if (has_pkg("officer")) downloadButton(ns("dl_docx"), "Download (.docx)", class = "btn-ghost")
      else span(class = "small muted", "Word download needs the R package officer (run install.R)."),
      downloadButton(ns("dl_md"), "Download (.md)", class = "btn-ghost"))))
}

section_drafts_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    observe({ ch <- project_picker_choices(ctx); updateSelectInput(session, "proj", choices = ch, selected = pick_sel(isolate(input$proj), ch, ctx$handoff$project)) })
    observe({
      q <- ctx$data$question_sets(); ids <- unique(q$set_id)
      ch <- named(ids, q$set_name[match(ids, q$set_id)]); updateSelectInput(session, "set", choices = ch, selected = pick_sel(isolate(input$set), ch))
    })
    proj <- reactive({ pr <- ctx$data$projects(); pr[pr$project_id == (input$proj %||% ""), , drop = FALSE] })
    qs <- reactive({ q <- ctx$data$question_sets(); q <- q[q$set_id == (input$set %||% ""), , drop = FALSE]; q[order(num(q$question_no)), , drop = FALSE] })
    answers <- reactive({ a <- ctx$table("answers")(); a[a$project_id == (input$proj %||% "") & a$set_id == (input$set %||% ""), , drop = FALSE] })
    latest <- reactive({ a <- answers(); a <- a[order(num(a$version)), , drop = FALSE]; a[!duplicated(a$question_no, fromLast = TRUE), , drop = FALSE] })
    key <- function(qno) paste0("a_", gsub("[^A-Za-z0-9]", "_", qno))

    output$summary <- renderUI({
      if (!length(project_picker_choices(ctx))) return(project_empty_note())
      q <- qs(); req(nrow(q) > 0); l <- latest()
      words <- vapply(q$question_no, function(n) num(l$words[l$question_no == n][1] %||% 0), 1)
      over <- sum(num(q$word_limit) > 0 & words > num(q$word_limit))
      note(if (over) "warn" else "info", sprintf("%d of %d questions have a saved answer. %d over the word limit.", sum(words > 0), nrow(q), over),
           if (is_true(q$is_example[1])) " This is an example question set: check it against the current brief.")
    })

    # rebuilt only when the project or set changes, never by the background refresh (typing is kept)
    output$questions <- renderUI({
      input$proj; input$set
      q <- isolate(qs()); r <- isolate(proj()); req(nrow(q) > 0, nrow(r) > 0); l <- isolate(latest())
      tagList(lapply(seq_len(nrow(q)), function(i) {
        n <- q$question_no[i]; prev <- l$text[l$question_no == n][1] %||% ""; v <- l$version[l$question_no == n][1] %||% ""
        div(class = "q-block cp-card",
          h5(n, ". ", q$question[i]), if (nzchar(q$guidance[i])) p(class = "small muted", q$guidance[i]),
          div(class = "cp-ans", `data-limit` = num(q$word_limit[i]),
              textAreaInput(ns(key(n)), NULL, value = if (is.na(prev)) "" else prev, rows = 7, width = "100%"),
              div(class = "wc", "")),
          div(class = "btn-row",
            tags$button(class = "btn btn-ghost sm", onclick = js_click(ns("draft"), n), icon("robot"), " Draft with Claude"),
            tags$button(class = "btn btn-brand sm", onclick = js_click(ns("save_q"), n), "Save"),
            if (nzchar(v %||% "") && !is.na(v)) span(class = "small muted", "Version ", v)))
      }))
    })

    save_one <- function(n) {
      txt <- input[[key(n)]] %||% ""; l <- latest()
      if (identical(txt, l$text[l$question_no == n][1] %||% "")) return(FALSE)
      v <- max(c(0, num(answers()$version[answers()$question_no == n]))) + 1
      store_append("answers", data.frame(project_id = input$proj, set_id = input$set, question_no = n, version = v, text = txt,
        words = word_count(txt), updated_by = ctx$user(), updated_at = now_ts(), stringsAsFactors = FALSE), user = ctx$user(), log = FALSE)
      TRUE
    }
    observeEvent(input$save_q, { if (save_one(input$save_q)) { ctx$bump(); showNotification("Saved as a new version.", type = "message") }
                                 else showNotification("No change to save.", type = "message") })
    observeEvent(input$save_all, {
      n <- sum(vapply(qs()$question_no, save_one, TRUE)); ctx$bump()
      if (n) log_change(ctx$user(), "save", "answers", sprintf("%d answer(s) for %s", n, input$proj))
      showNotification(sprintf("Saved %d changed answer(s).", n), type = "message")
    })

    bid_context <- function() {
      r <- proj(); p <- ctx$programmes(); pr <- p[p$programme_id == r$programme_id, , drop = FALSE]
      c <- ctx$data$consortium(); c <- c[c$programme_id == r$programme_id & c$status != "declined", , drop = FALSE]
      t <- ctx$data$tasks(); t <- t[t$project_id == r$project_id, , drop = FALSE]
      rk <- latest_by(store_read("risks"), "risk_id"); rk <- rk[rk$project_id == r$project_id & !rk$status %in% c("deleted", "closed"), , drop = FALSE]
      b <- latest_by(store_read("budget"), c("project_id", "partner", "category")); b <- b[b$project_id == r$project_id & num(b$amount_gbp) > 0, , drop = FALSE]
      paste0("PROGRAMME: ", pr$programme_name[1] %||% "", " (", pr$funder[1] %||% "", "). ", pr$summary[1] %||% "", " Themes: ", pr$themes[1] %||% "",
        ". Conditions: ", pr$conditions[1] %||% "", ". Funding: ", pr$amount_text[1] %||% "", ".\n",
        "OUR COMPANY: ", ctx$settings()$company_profile %|% "(no profile)", "\n",
        "PROJECT: ", r$title, ", ", r$start_date, " to ", r$end_date, ".\n",
        "CONSORTIUM: ", if (nrow(c)) paste(sprintf("%s (%s, %s)", c$organisation %|% c$email, c$role, c$status), collapse = "; ") else "just us", "\n",
        "WORK PACKAGES: ", if (nrow(t)) paste(sprintf("%s - %s (%s to %s)", t$work_package, t$task, t$start_date, t$end_date), collapse = "; ") else "not planned yet", "\n",
        "RISKS: ", if (nrow(rk)) paste(sprintf("%s (L%s x I%s; %s)", rk$risk, rk$likelihood, rk$impact, rk$mitigation), collapse = "; ") else "none recorded", "\n",
        "BUDGET: ", if (nrow(b)) paste0("total cost GBP ", fmt_num(sum(num(b$amount_gbp))), "; grant GBP ",
                                         fmt_num(sum(num(b$amount_gbp) * num(b$funded_pct) / 100)), "; by partner: ",
                                         { tp <- tapply(num(b$amount_gbp), b$partner, sum); paste(names(tp), fmt_num(tp), collapse = ", ") }) else "not set yet")
    }
    observeEvent(input$draft, {
      n <- input$draft; q <- qs(); qi <- q[q$question_no == n, , drop = FALSE]; req(nrow(qi) > 0)
      if (!claude_ready()) return(showNotification("No Claude API key is set (Admin > Claude API).", type = "error"))
      lim <- num(qi$word_limit); cur <- input[[key(n)]] %||% ""
      prompt <- paste0("You are writing one answer of a funding application.\n\nQUESTION ", n, ": ", qi$question, "\n",
        if (nzchar(qi$guidance)) paste0("GUIDANCE: ", qi$guidance, "\n"),
        if (lim > 0) paste0("WORD LIMIT: ", lim, " words. Stay under it (aim for 90 to 95 percent).\n"),
        "\nWHAT WE KNOW ABOUT THE BID:\n", bid_context(), "\n\n",
        if (nzchar(trimws(cur))) paste0("CURRENT DRAFT (improve it, keep facts that are right):\n", cur, "\n\n"),
        "Write only the answer text. Plain British English, specific, no headings unless the question asks for them. ",
        "Do not invent numbers, names or results that are not given above; write [to confirm] where a fact is missing.")
      res <- withProgress(message = paste("Drafting answer", n, "..."), tryCatch(claude_call(prompt, max_tokens = 3000)$text,
                          error = function(e) structure(safe_error_text(e), class = "err")))
      if (inherits(res, "err")) return(showNotification(res, type = "error", duration = 10))
      updateTextAreaInput(session, key(n), value = res)
      showNotification(sprintf("Draft ready (%d words). Check it, then Save.", word_count(res)), type = "message")
    })

    export_rows <- function() {
      q <- qs(); data.frame(no = q$question_no, question = q$question, limit = q$word_limit,
        text = vapply(q$question_no, function(n) input[[key(n)]] %||% "", ""), stringsAsFactors = FALSE)
    }
    fname <- function(ext) paste0(gsub("[^A-Za-z0-9]+", "_", proj()$title %||% "answers"), "_", format(Sys.Date(), "%Y%m%d"), ext)
    output$dl_md <- downloadHandler(filename = function() fname(".md"), content = function(file) {
      d <- export_rows()
      writeLines(c(paste("#", proj()$title), "", unlist(lapply(seq_len(nrow(d)), function(i) c(
        paste0("## ", d$no[i], ". ", d$question[i]), sprintf("*%d words%s*", word_count(d$text[i]), if (num(d$limit[i]) > 0) paste0(" of ", d$limit[i]) else ""),
        "", d$text[i], "")))), file, useBytes = TRUE)
    })
    output$dl_docx <- downloadHandler(filename = function() fname(".docx"), content = function(file) {
      need_pkg("officer"); d <- export_rows(); doc <- officer::read_docx()
      doc <- officer::body_add_par(doc, proj()$title, style = "heading 1")
      for (i in seq_len(nrow(d))) {
        doc <- officer::body_add_par(doc, paste0(d$no[i], ". ", d$question[i]), style = "heading 2")
        doc <- officer::body_add_par(doc, sprintf("%d words%s", word_count(d$text[i]), if (num(d$limit[i]) > 0) paste0(" of ", d$limit[i]) else ""))
        for (para in strsplit(d$text[i], "\n\n+")[[1]]) doc <- officer::body_add_par(doc, para, style = "Normal")
      }
      print(doc, target = file)
    })
  })
}
