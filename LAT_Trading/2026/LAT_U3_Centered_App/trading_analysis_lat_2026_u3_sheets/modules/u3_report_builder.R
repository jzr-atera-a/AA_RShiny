# modules/u3_report_builder.R
# Unit 3 Report Builder: checklist and coverage of the trading period, task drafts with live word counts, SWOT boxes with
# evidence from the BigQuery records, labelled figures, References, and the LAT Answer Sheet (.docx + PDF + Dropbox)
# filled with the student's OWN text. The app never writes, suggests or rewrites assessed text.

u3rb_box <- function(...) tags$div(style = "background:#f6f8fb; border-radius:8px; padding:10px 14px; margin-bottom:12px; color:#2c3e50;", ...)
u3rb_h <- function(x) tags$h4(style = "color:#002C3C; font-weight:800; margin:6px 0 10px 0;", x)
u3rb_note <- function(...) tags$div(style = "font-size:12px; color:#64748b; margin:4px 0 10px 0; line-height:1.5;", ...)

u3_report_builder_ui <- function(id) {
  ns <- NS(id)
  draft <- function(k, rows = 16) tagList(
    u3rb_h(u3_task_titles[[k]]),
    u3rb_note(tags$b("The brief asks for: "), paste(u3_task_points[[k]], collapse = " · ")),
    textAreaInput(ns(paste0("txt_", k)), NULL, rows = rows, width = "100%", placeholder = "Paste or type your own answer here. A blank line starts a new paragraph."),
    uiOutput(ns(paste0("wc_", k))))
  tagList(
    tags$div(style = "background: linear-gradient(135deg, #002C3C 0%, #008A82 100%); border-radius: 12px; padding: 16px 20px; margin-bottom: 14px; color: #ffffff;",
      tags$h3(style = "margin:0 0 4px 0; font-size:19px; font-weight:800; color:#ffffff;", "Unit 3 Report Builder"),
      tags$div(style = "font-size:13px; color:#eafffb; line-height:1.6;",
        "Checks your records against the brief, counts your words, draws labelled figures from your trades, builds the References list and puts YOUR text into the LAT Answer Sheet. ",
        tags$b("It never writes or rewrites your answers."), " Unit 3 is assessed on your own words and judgement and is checked with Turnitin and AI detection.")),
    tabBox(width = 12, id = ns("tabs"),
      tabPanel("1. Checklist & coverage",
        u3rb_h("Answer Sheet instructions"), uiOutput(ns("instr")),
        u3rb_h("Trading period: Morning Sheets and Trade Sheets day by day"),
        u3rb_note("A sheet is 'complete' when the missing-field check in Trading Records > Exports finds nothing (boxes only you can write count as missing until written)."),
        uiOutput(ns("cov_summary")), DT::DTOutput(ns("cov_table"))),
      tabPanel("2. Your task answers",
        u3rb_note("Drafts are saved to BigQuery (trading_settings) with the Save button, so they survive a restart. Word counts follow Word (anything with a letter or digit is a word). The brief allows 3150-3850 words in total, excluding references."),
        uiOutput(ns("wc_total")),
        actionButton(ns("save_drafts"), "Save drafts", icon = icon("floppy-disk"), class = "btn-success", style = "color:#ffffff; font-weight:700;"), tags$br(), tags$br(),
        draft("task1"), draft("task2"), draft("task3", 10),
        u3rb_h("Task 3 SWOT boxes (optional: printed after your Task 3 text, under bold headings)"),
        u3rb_box(tags$div(style = "font-weight:800; margin-bottom:4px;", "Evidence from your records"), uiOutput(ns("swot_evidence"))),
        fluidRow(column(6, textAreaInput(ns("swot_S"), tags$b("Strengths"), rows = 4, width = "100%"), textAreaInput(ns("swot_W"), tags$b("Weaknesses"), rows = 4, width = "100%")),
                 column(6, textAreaInput(ns("swot_O"), tags$b("Opportunities"), rows = 4, width = "100%"), textAreaInput(ns("swot_T"), tags$b("Threats"), rows = 4, width = "100%")))),
      tabPanel("3. Figures & numbers",
        fluidRow(column(3, selectInput(ns("fig_scope"), tags$b("Trades"), c("Assessed trades only" = "ASSESSED", "All trades" = "ALL", "Practice trades only" = "PRACTICE")))),
        u3rb_note("Every figure is labelled as your own work from your IG demo-account records, as instruction 5 asks. Choose in tab 5 which ones go into which task."),
        uiOutput(ns("fig_list")),
        downloadButton(ns("dl_figs"), "Download all figures (.zip of PNG)"),
        u3rb_h("Numbers for Task 2 (from Trading Records)"), uiOutput(ns("num_tiles")),
        fluidRow(column(6, u3rb_h("By asset"), tableOutput(ns("t_asset"))), column(6, u3rb_h("By strategy"), tableOutput(ns("t_strat")))),
        u3rb_h("Deviations you recorded (plan not followed)"), tableOutput(ns("t_dev"))),
      tabPanel("4. References",
        u3rb_note("Harvard style, sorted A-Z. Web pages Claude used for your Morning Sheets are listed automatically (saved with each search). Add books, articles or course notes you used, one per line, in the same style."),
        checkboxGroupInput(ns("ref_base"), tags$b("Standard sources to include"), inline = TRUE, selected = c("ig", "lat", "yahoo", "claude"),
                           choices = c("IG platform (demo)" = "ig", "LAT Unit 3 brief" = "lat", "Yahoo Finance data" = "yahoo", "Claude (AI tool, transcription only)" = "claude")),
        uiOutput(ns("ref_web_pick")),
        textAreaInput(ns("ref_extra"), tags$b("Your own references (one per line)"), rows = 5, width = "100%"),
        u3rb_h("References list"), uiOutput(ns("ref_list"))),
      tabPanel("5. Build the Answer Sheet",
        fluidRow(column(3, textInput(ns("as_name"), tags$b("Student name"), "")), column(3, textInput(ns("as_id"), tags$b("LAT Student ID"), "")),
                 column(3, textInput(ns("as_abe"), tags$b("ABE Registration No."), "")), column(3, dateInput(ns("as_date"), tags$b("Date"), Sys.Date()))),
        fluidRow(column(4, checkboxGroupInput(ns("fig_t1"), tags$b("Figures in Task 1"), choices = u3_figure_defs_choices())),
                 column(4, checkboxGroupInput(ns("fig_t2"), tags$b("Figures in Task 2"), choices = u3_figure_defs_choices(), selected = c("equity", "realr", "asset", "adherence"))),
                 column(4, checkboxGroupInput(ns("fig_t3"), tags$b("Figures in Task 3"), choices = u3_figure_defs_choices(), selected = c("strategy")))),
        u3rb_box(tags$div(style = "font-weight:800;", "Your own pictures (for example an annotated IG chart for Task 1)"),
          fluidRow(column(3, selectInput(ns("own_task"), "Task", c("Task 1" = "task1", "Task 2" = "task2", "Task 3" = "task3"))),
                   column(5, textInput(ns("own_cap"), "Caption", "", placeholder = "Brent crude 1-hour chart with pivot levels")),
                   column(4, selectInput(ns("own_src"), "Source", c("Own work (annotated IG platform chart)" = "Source: own work, annotated screenshot of the IG trading platform.",
                                                                     "IG platform screenshot" = "Source: IG trading platform (demo account), screenshot by the author.",
                                                                     "Own work" = "Source: own work.")))),
          fluidRow(column(6, fileInput(ns("own_file"), NULL, multiple = FALSE, accept = c("image/png", "image/jpeg", ".png", ".jpg", ".jpeg"))),
                   column(3, actionButton(ns("own_add"), "Add picture", icon = icon("plus")))),
          tableOutput(ns("own_list")), actionButton(ns("own_clear"), "Remove all own pictures", icon = icon("trash"))),
        checkboxInput(ns("as_swot"), "Print the SWOT boxes after the Task 3 text", TRUE),
        uiOutput(ns("as_check")),
        downloadButton(ns("dl_docx"), "Download Answer Sheet (.docx)"), downloadButton(ns("dl_pdf"), "Download Answer Sheet (PDF)"),
        actionButton(ns("as_dbx"), "Save Word + PDF to Dropbox", icon = icon("dropbox")), uiOutput(ns("as_dbx_out")),
        u3rb_note("Open the Word file and read it through before you submit: check numbering, spacing and that every figure is referred to in your text."))
    )
  )
}
u3_figure_defs_choices <- function() setNames(names(u3_figure_defs), unname(u3_figure_defs))

u3_report_builder_server <- function(id, store, quiet = FALSE, active = reactive(TRUE)) {
  moduleServer(id, function(input, output, session) {
    msg <- function(t, type = "message") if (!quiet) showNotification(t, type = type, duration = 6)
    refresh <- reactiveVal(0); bump <- function() refresh(isolate(refresh()) + 1)
    # read BigQuery only while this tab is open: once each time it is opened, and after a save here.
    # (It used to re-read all six tables every 15 seconds, all day: the endless "Job complete / Billed: 0 B" lines.)
    poll <- reactive({ req(isTRUE(active())); refresh() })
    rd <- function(name) reactive({ poll(); tr_read_current(store, name) })
    settings <- rd("settings"); sheets <- rd("morning_sheets"); levels <- rd("morning_levels"); trades <- rd("trades"); evidence <- rd("evidence"); events <- rd("trade_events")
    sv <- reactive({ s <- settings(); setNames(as.list(s$setting_value), s$setting_key) })
    pstart <- reactive(tryCatch(as.Date(tr_or(sv()$period_start, "2026-10-19")), error = function(e) as.Date("2026-10-19")))
    pend <- reactive(tryCatch(as.Date(tr_or(sv()$period_end, "2026-11-13")), error = function(e) as.Date("2026-11-13")))
    opening <- reactive(tr_or(tr_num(sv()$opening_balance), 10000))

    # ---- restore saved drafts once
    loaded <- reactiveVal(FALSE)
    observe({
      s <- sv(); if (isolate(loaded()) || !length(s)) return(); loaded(TRUE)
      for (k in c("task1", "task2", "task3")) if (!is.null(s[[paste0("u3_", k, "_text")]])) updateTextAreaInput(session, paste0("txt_", k), value = s[[paste0("u3_", k, "_text")]])
      for (z in c("S", "W", "O", "T")) if (!is.null(s[[paste0("u3_swot_", z)]])) updateTextAreaInput(session, paste0("swot_", z), value = s[[paste0("u3_swot_", z)]])
      if (!is.null(s$u3_refs_extra)) updateTextAreaInput(session, "ref_extra", value = s$u3_refs_extra)
      if (!is.null(s$u3_abe)) updateTextInput(session, "as_abe", value = s$u3_abe)
      updateTextInput(session, "as_name", value = tr_or(s$trader_name, "")); updateTextInput(session, "as_id", value = tr_or(s$student_id, ""))
    })
    observeEvent(input$save_drafts, {
      keys <- c(paste0("u3_", c("task1", "task2", "task3"), "_text"), paste0("u3_swot_", c("S", "W", "O", "T")), "u3_refs_extra", "u3_abe")
      vals <- c(input$txt_task1, input$txt_task2, input$txt_task3, input$swot_S, input$swot_W, input$swot_O, input$swot_T, input$ref_extra, input$as_abe)
      vals <- unname(vapply(vals, function(v) tr_or(v, ""), "")); prev <- sv()
      ch <- vapply(seq_along(keys), function(i) !identical(tr_or(prev[[keys[i]]], ""), vals[i]), TRUE)   # only what changed (append-only table)
      if (!any(ch)) { msg("Nothing has changed since the last save."); return() }
      r <- store$write("settings", data.frame(setting_key = keys[ch], setting_value = vals[ch], stringsAsFactors = FALSE)); bump()
      msg(if (identical(r, "bigquery")) "Drafts saved to BigQuery." else "Drafts saved in this session only (BigQuery not connected).", if (identical(r, "bigquery")) "message" else "warning")
    })

    # ---- word counts
    counts <- reactive(c(task1 = u3_word_count(input$txt_task1), task2 = u3_word_count(input$txt_task2), task3 = u3_word_count(input$txt_task3)))
    for (k in c("task1", "task2", "task3")) local({ kk <- k; kn <- as.integer(substr(k, 5, 5))
      output[[paste0("wc_", kk)]] <- renderUI({ n <- counts()[[kk]]; st <- u3_count_status(n, u3_targets[[kk]])
        tags$div(style = paste0("font-size:12.5px; margin:-4px 0 14px 0; font-weight:700; color:", if (grepl("within", st)) "#15803d" else if (n == 0) "#64748b" else "#b45309", ";"),
                 sprintf("Word Count: %s (target %s): %s", formatC(n, big.mark = ","), formatC(u3_targets[[kk]], big.mark = ","), st),
                 if (isFALSE(u3_numbering_ok(input[[paste0("txt_", kk)]], kn))) tags$span(style = "color:#b45309; margin-left:10px;", sprintf("Start with '%d.' (instruction 2)", kn)),
                 if (length(q <- u3_long_quotes(input[[paste0("txt_", kk)]]))) tags$span(style = "color:#b45309; margin-left:10px;", sprintf("%d long quotation(s) (instruction 4)", length(q)))) }) })
    output$wc_total <- renderUI({ n <- sum(counts()); ok <- n >= u3_total_range[1] && n <= u3_total_range[2]
      tags$div(style = paste0("font-size:13px; font-weight:800; margin-bottom:8px; color:", if (ok) "#15803d" else "#b45309", ";"),
               sprintf("Total: %s words (brief: %s-%s, excluding references)%s", formatC(n, big.mark = ","), formatC(u3_total_range[1], big.mark = ","), formatC(u3_total_range[2], big.mark = ","), if (ok) " ✓" else "")) })

    # ---- checklist and coverage
    gaps_n <- function(tr) { t <- trades(); legs <- t[(t$trade_id == tr$trade_id | (!is.na(t$parent_trade_id) & t$parent_trade_id == tr$trade_id)) & t$status == "CLOSED", , drop = FALSE]
      nrow(tr_trade_gaps(tr, legs, tr_pictures_for(evidence(), tr$trade_id))) }
    cov <- reactive(u3_coverage(sheets(), levels(), tr_scope_filter(trades(), "ASSESSED"), evidence(), pstart(), pend(), gaps_n))
    output$cov_summary <- renderUI({ d <- cov(); if (is.null(d)) return(NULL); past <- as.Date(d$Date, "%d/%m/%Y") <= Sys.Date()
      tags$div(style = "font-size:13px; margin-bottom:8px;", sprintf("Up to today: %d of %d Morning Sheets saved (%d complete) · %d assessed trade(s) · trading days in the period: %d.",
        sum(past & d$`Morning Sheet` != "missing"), sum(past), sum(past & d$`Morning Sheet` == "complete"), sum(d$Trades), nrow(d))) })
    output$cov_table <- DT::renderDT({ d <- cov(); if (is.null(d)) return(NULL)
      DT::datatable(d, rownames = FALSE, options = list(dom = "t", pageLength = 40, ordering = FALSE)) |>
        DT::formatStyle("Morning Sheet", color = DT::styleEqual(c("missing", "complete"), c("#b91c1c", "#15803d")), fontWeight = "bold") })
    output$instr <- renderUI({
      s <- sv(); n <- counts(); fig_ok <- TRUE
      txts <- list(input$txt_task1, input$txt_task2, input$txt_task3)
      numb <- vapply(1:3, function(k) u3_numbering_ok(txts[[k]], k), NA)
      quotes <- unlist(lapply(txts, u3_long_quotes))
      st <- c(nzchar(tr_or(s$trader_name, "")) && nzchar(tr_or(s$student_id, "")), if (all(is.na(numb))) NA else all(numb, na.rm = TRUE),
              length(refs()) > 0, if (all(n == 0)) NA else !length(quotes), fig_ok, all(n > 0))
      note <- c(if (st[1]) paste(s$trader_name, s$student_id, "(from Trading Records > Setup; printed in the student table)") else "Set your name and LAT ID in Trading Records > Setup",
                if (all(is.na(numb))) "Checked when you write: each answer should start with its task number (for example '1.' or 'Task 1') and number its sub-points"
                else if (all(numb, na.rm = TRUE)) "Each answer starts with its task number" else paste("Start with the task number:", paste(sprintf("Task %d", which(!numb)), collapse = ", ")),
                sprintf("%d reference(s), built in tab 4 (web addresses in your text are added automatically) and printed at the end", length(refs())),
                if (length(quotes)) sprintf("%d quotation(s) longer than 30 words: shorten or paraphrase: %s", length(quotes), paste(substr(quotes, 1, 60), collapse = " | ")) else "No quotation longer than 30 words found",
                "Figures from the app carry 'Figure n' and a source line; give your own pictures a caption and source in tab 5",
                "Written automatically above each answer from the live count")
      tags$table(class = "table table-condensed", style = "font-size:12.5px; background:#ffffff;",
        tags$tbody(lapply(seq_along(u3_instructions), function(i) tags$tr(
          tags$td(style = "width:24px; font-weight:800;", if (isTRUE(st[i])) tags$span(style = "color:#15803d;", "✓") else if (is.na(st[i])) tags$span(style = "color:#1d4ed8;", "•") else tags$span(style = "color:#b45309;", "!")),
          tags$td(tags$b(sprintf("%d. %s", i, u3_instructions[i]))), tags$td(note[i])))))
    })

    # ---- evidence, figures, numbers
    closed <- reactive({ t <- tr_scope_filter(trades(), tr_or(input$fig_scope, "ASSESSED")); t[t$status == "CLOSED" & !is.na(t$net_pnl_gbp), , drop = FALSE] })
    stats <- reactive(tr_stats(closed(), opening()))
    figs <- reactive({ cl <- closed(); if (!nrow(cl)) return(NULL); u3_make_figures(cl, opening(), dir = file.path(tempdir(), paste0("u3fig_", session$token))) })
    output$fig_list <- renderUI({
      f <- figs(); if (is.null(f) || !nrow(f)) return(u3rb_box("No closed trades yet: figures appear as soon as a trade is closed in Trading Records."))
      tagList(lapply(seq_len(nrow(f)), function(i) { id <- paste0("fig_img_", f$key[i])
        output[[id]] <- renderImage(list(src = f$file[i], width = "100%", alt = f$title[i]), deleteFile = FALSE)
        tags$div(style = "display:inline-block; width:48%; vertical-align:top; margin:0 1% 14px 0;",
          tags$div(style = "font-size:12.5px; font-weight:800; color:#002C3C;", paste0(f$title[i], ".")), tags$div(style = "font-size:11.5px; color:#64748b;", u3_figure_source),
          imageOutput(session$ns(id), height = "auto")) }))
    })
    output$dl_figs <- downloadHandler(filename = function() paste0("U3_figures_", format(Sys.Date(), "%d-%m-%Y"), ".zip"),
      content = function(file) { f <- figs(); if (is.null(f)) stop("No figures yet."); zip::zip(file, files = basename(f$file), root = dirname(f$file[1])) })
    output$num_tiles <- renderUI({ s <- stats(); if (is.null(s)) return(NULL); m <- s$summary
      v <- c(Trades = m$trades, `Win rate` = tr_fmt_pct(m$win_rate), `Net P/L` = paste0("£", tr_fmt_num(m$total_pnl_gbp)), Return = tr_fmt_pct(m$return_pct, 2),
             `Avg planned RRR` = tr_fmt_num(m$avg_initial_rrr), `Avg Real R` = tr_fmt_num(m$avg_real_r), `Max drawdown` = tr_fmt_pct(m$max_drawdown_pct, 2), Adherence = tr_fmt_pct(m$adherence_rate))
      tags$div(style = "display:flex; flex-wrap:wrap;", lapply(names(v), function(k) tr_tile(k, v[[k]]))) })
    pct <- function(d) { if (is.null(d)) return(NULL); if ("Win rate" %in% names(d)) d$`Win rate` <- sprintf("%.0f%%", 100 * d$`Win rate`); d }
    output$t_asset <- renderTable({ s <- stats(); req(s); d <- pct(s$by_asset); d$Group <- vapply(d$Group, tr_asset_label, ""); d }, digits = 2, striped = TRUE)
    output$t_strat <- renderTable({ s <- stats(); req(s); pct(s$by_strategy) }, digits = 2, striped = TRUE)
    output$t_dev <- renderTable({ cl <- closed(); d <- cl[!is.na(cl$plan_followed) & !cl$plan_followed, , drop = FALSE]
      if (!nrow(d)) return(data.frame(Note = "No deviations recorded."))
      data.frame(Trade = d$trade_sheet_name, Type = d$deviation_type, `What you wrote` = d$deviation_note, `P/L (GBP)` = d$net_pnl_gbp, check.names = FALSE) }, striped = TRUE)
    output$swot_evidence <- renderUI({ s <- stats(); if (is.null(s)) return("No closed trades yet.")
      bs <- s$by_strategy; ba <- s$by_asset; m <- s$summary
      best <- bs[which.max(bs$`Avg Real R`), ]; worst <- bs[which.min(bs$`Avg Real R`), ]
      tags$ul(style = "font-size:12.5px; margin:0; padding-left:18px;",
        tags$li(sprintf("%d closed trade(s): %d won, %d lost; net £%s; average Real R %s; planned RRR %s.", m$trades, m$wins, m$losses, tr_fmt_num(m$total_pnl_gbp), tr_fmt_num(m$avg_real_r), tr_fmt_num(m$avg_initial_rrr))),
        tags$li(sprintf("Best strategy by average R: %s (%d trades, %s R). Weakest: %s (%d trades, %s R).", best$Group, best$Trades, tr_fmt_num(best$`Avg Real R`), worst$Group, worst$Trades, tr_fmt_num(worst$`Avg Real R`))),
        tags$li(sprintf("Plan followed on %d of %d trades with a record; %d deviation(s).", m$followed, m$adherence_recorded, m$deviations)),
        tags$li(sprintf("Exit codes: %s.", paste(sprintf("%s %d", s$by_exit$Group, s$by_exit$Trades), collapse = ", "))),
        tags$li(sprintf("Assets: %s.", paste(sprintf("%s £%s", vapply(ba$Group, tr_asset_label, ""), tr_fmt_num(ba$`Net P/L (GBP)`)), collapse = "; ")))) })

    # ---- references
    web <- reactive(u3_web_sources(evidence()))
    output$ref_web_pick <- renderUI({ w <- web(); if (is.null(w) || !nrow(w)) return(u3rb_note("No web sources saved yet (they are saved when Claude searches the web on the Morning Sheet tab)."))
      checkboxGroupInput(session$ns("ref_web"), tags$b(sprintf("Web pages used (%d): untick any you did not rely on", nrow(w))), choices = setNames(w$url, paste0(ifelse(nzchar(w$title), w$title, w$url), " (", format(w$accessed, "%d/%m"), ")")),
                         selected = w$url[w$kind == "cited" | !("cited" %in% w$kind)]) })
    refs <- reactive({ w <- web(); if (!is.null(w)) w <- w[w$url %in% tr_or(input$ref_web, character(0)), , drop = FALSE]
      u <- u3_urls(paste(input$txt_task1, input$txt_task2, input$txt_task3, input$swot_S, input$swot_W, input$swot_O, input$swot_T))   # links you cite in your text
      if (length(u)) w <- rbind(w, data.frame(url = u, title = "", accessed = Sys.Date(), kind = "your text", stringsAsFactors = FALSE)[!(u %in% if (is.null(w)) character(0) else w$url), , drop = FALSE])
      u3_references(tr_or(input$ref_base, character(0)), w, unlist(strsplit(tr_or(input$ref_extra, ""), "\n")), c(format(pstart()), format(pend()))) })
    output$ref_list <- renderUI(u3rb_box(if (!length(refs())) "No references selected." else lapply(refs(), function(r) tags$p(style = "font-size:12.5px; margin:0 0 6px 0; padding-left:18px; text-indent:-18px;", r))))

    # ---- own pictures
    own <- reactiveVal(data.frame(task = character(0), path = character(0), caption = character(0), stringsAsFactors = FALSE))
    observeEvent(input$own_add, { f <- input$own_file; if (is.null(f)) { msg("Choose the picture first.", "warning"); return() }
      if (!nzchar(trimws(tr_or(input$own_cap, "")))) { msg("Give the picture a caption (instruction 5: label every diagram).", "warning"); return() }
      keep <- file.path(tempdir(), paste0("u3own_", session$token, "_", basename(f$datapath), ".", tools::file_ext(f$name))); file.copy(f$datapath, keep, overwrite = TRUE)
      own(rbind(own(), data.frame(task = input$own_task, path = keep, caption = paste0(trimws(input$own_cap), ". ", input$own_src), stringsAsFactors = FALSE))) })
    observeEvent(input$own_clear, own(own()[0, ]))
    output$own_list <- renderTable({ o <- own(); if (!nrow(o)) return(NULL); data.frame(Task = sub("task", "Task ", o$task), Caption = o$caption) })

    # ---- the Answer Sheet
    fig_table <- reactive({
      f <- figs(); out <- own()[0, ]
      if (!is.null(f) && nrow(f)) for (k in c("task1", "task2", "task3")) { pick <- tr_or(input[[paste0("fig_t", substr(k, 5, 5))]], character(0)); g <- f[f$key %in% pick, , drop = FALSE]
        if (nrow(g)) out <- rbind(out, data.frame(task = k, path = g$file, caption = paste0(g$title, ". ", u3_figure_source), stringsAsFactors = FALSE)) }
      o <- own(); out <- rbind(out, o); out[order(match(out$task, c("task1", "task2", "task3"))), , drop = FALSE] })
    output$as_check <- renderUI({ n <- counts(); probs <- character(0)
      if (!nzchar(trimws(tr_or(input$as_name, "")))) probs <- c(probs, "Student name is empty.")
      if (!grepl("^D\\d{6,}$", trimws(tr_or(input$as_id, "")))) probs <- c(probs, "LAT Student ID should look like D100xxxx.")
      for (k in names(n)) if (n[[k]] == 0) probs <- c(probs, sprintf("%s has no text yet.", u3_task_titles[[k]]))
      if (!length(refs())) probs <- c(probs, "The References list is empty.")
      tags$div(style = paste0("font-size:12.5px; margin:8px 0; color:", if (length(probs)) "#b45309" else "#15803d", ";"),
        if (length(probs)) tagList(tags$b("Before you build: "), tags$ul(lapply(probs, tags$li))) else sprintf("✓ Ready: %s words in total, %d figure(s), %d reference(s).", formatC(sum(n), big.mark = ","), nrow(fig_table()), length(refs()))) })
    build <- function(file) u3_answer_sheet_docx(file, input$as_name, input$as_id, tr_or(input$as_abe, ""), input$as_date,
                                                 texts = list(task1 = input$txt_task1, task2 = input$txt_task2, task3 = input$txt_task3), figs = fig_table(), refs = refs(),
                                                 swot = if (isTRUE(input$as_swot)) list(S = tr_or(input$swot_S, ""), W = tr_or(input$swot_W, ""), O = tr_or(input$swot_O, ""), T = tr_or(input$swot_T, "")) else NULL)
    fname <- function(ext) u3_answer_filename(tr_or(input$as_name, "Student"), ext)
    output$dl_docx <- downloadHandler(filename = function() fname("docx"), content = function(file) build(file))
    output$dl_pdf <- downloadHandler(filename = function() fname("pdf"), content = function(file) {
      d <- tempfile("u3as_"); dir.create(d); f <- file.path(d, fname("docx")); build(f); p <- tr_docx_to_pdf(f, d)
      if (is.na(p)) stop("PDF conversion needs LibreOffice on this computer. Download the Word file and use Save as PDF."); file.copy(p, file, overwrite = TRUE) })
    dbx_res <- reactiveVal(NULL)
    observeEvent(input$as_dbx, {
      d <- tempfile("u3as_"); dir.create(d); f <- file.path(d, fname("docx"))
      ok <- tryCatch({ build(f); TRUE }, error = function(e) { msg(conditionMessage(e), "error"); FALSE }); if (!ok) return()
      p <- tr_docx_to_pdf(f, d); s <- sv()
      res <- tr_save_sheet(c(f, p), "other")   # C:/Users/jfz00/Dropbox/London Academy of Trading/Jose-F_Zubizarreta (fixed)
      dbx_res(res); msg(if (all(res$ok)) "Saved to Dropbox." else "Some files were not saved: see below.", if (all(res$ok)) "message" else "warning") })
    output$as_dbx_out <- renderUI({ r <- dbx_res(); if (is.null(r)) return(NULL)
      tags$div(style = "font-size:12.5px; margin:6px 0;", lapply(seq_len(nrow(r)), function(i) tags$div(paste0(if (r$ok[i]) "✓ " else "✗ ", r$file[i], if (nzchar(r$where[i])) paste0(" → ", r$where[i]) else "", ": ", r$note[i])))) })
  })
}
