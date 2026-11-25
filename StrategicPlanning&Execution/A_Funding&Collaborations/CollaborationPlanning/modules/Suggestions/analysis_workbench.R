# ---- module ----------------------------------------------
# id:           analysis_workbench
# name:         Analysis workbench
# icon:         flask
# description:  Owner only: write instructions for Claude, run the analysis of a suggestion, parse it into tables, classify it, choose who sees it, and copy it to Google Drive
# packages:     shiny, DT
# -----------------------------------------------------------
# Claude answers in JSON tables (R/analysis.R). Saved to the analyses table; access_emails is the list of people
# who can open it in Analysis library (the person who made the suggestion is always on it).

CELL_LIMIT <- 45000   # Google Sheets holds at most 50,000 characters in one cell

analysis_workbench_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("guard")),
    layout_columns(col_widths = c(5, 7),
      tagList(
        card("1. Suggestion",
          selectInput(ns("sid"), NULL, NULL, width = "100%"),
          uiOutput(ns("sug_view"))),
        card("Analyses of this suggestion", DTOutput(ns("done")), p(class = "small muted", "Select one to open it below."))),
      tagList(
        card("2. Ask Claude",
          p(class = "small muted", "Open the instructions window to tell Claude what to look at, then run the analysis. ",
            "Answers come back as tables in British English, without long dashes."),
          div(class = "btn-row",
              actionButton(ns("instr"), "Instructions for Claude", class = "btn-ghost", icon = icon("pen-to-square")),
              actionButton(ns("run"), "Run the analysis", class = "btn-brand", icon = icon("robot"))),
          uiOutput(ns("instr_preview")),
          uiOutput(ns("run_status"))),
        card("3. Parse, check and classify",
          textAreaInput(ns("raw"), "Claude's answer (you can edit it, then parse again)", rows = 6, width = "100%"),
          actionButton(ns("parse"), "Parse into tables", class = "btn-ghost", icon = icon("table")),
          uiOutput(ns("parsed"))))),
    uiOutput(ns("save_box")))
}

analysis_workbench_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    instr <- reactiveVal(NULL); parsed <- reactiveVal(NULL); current <- reactiveVal("")   # current analysis_id ("" = new)
    output$guard <- renderUI(if (!ctx$is_owner()) note("bad", "Only the owner can use the analysis workbench."))
    sugs <- reactive(latest_suggestions(ctx$table("suggestions")()))
    ans <- reactive(latest_analyses(ctx$table("analyses")()))
    observe({
      d <- sugs(); d <- d[order(d$updated_at, decreasing = TRUE), , drop = FALSE]
      ch <- named(d$suggestion_id, paste0(d$title, " (", d$created_by, ", ", d$status, ")"))
      updateSelectInput(session, "sid", choices = ch, selected = pick_sel(isolate(input$sid), ch, ctx$handoff$suggestion))
    })
    observeEvent(ctx$handoff$suggestion, updateSelectInput(session, "sid", selected = ctx$handoff$suggestion), ignoreNULL = TRUE)
    sug <- reactive({ d <- sugs(); d[d$suggestion_id == (input$sid %||% ""), , drop = FALSE] })
    observeEvent(input$sid, { current(""); parsed(NULL); updateTextAreaInput(session, "raw", value = ""); output$run_status <- renderUI(NULL) })

    output$sug_view <- renderUI({
      s <- sug(); req(nrow(s) > 0)
      row <- function(l, v) if (nzchar(v)) tags$tr(tags$th(l), tags$td(v))
      tagList(tags$table(class = "kv",
        row("Kind", names(SUGGESTION_KINDS)[match(s$kind, SUGGESTION_KINDS)]), row("From", s$created_by), row("Description", s$description),
        if (nzchar(s$url)) tags$tr(tags$th("Link"), tags$td(tags$a(href = s$url, target = "_blank", rel = "noopener", s$url))),
        row("Ideas", s$ideas), row("Country / category / topic", paste(c(s$country, s$category, s$topic)[nzchar(c(s$country, s$category, s$topic))], collapse = " / ")),
        row("Funder", s$funder), row("Amount", s$amount_text), row("Deadline", s$deadline), row("Contact", s$contact), row("Notes", s$notes)))
    })
    output$done <- renderDT({
      a <- ans(); a <- a[a$suggestion_id == (input$sid %||% ""), , drop = FALSE]
      datatable(data.frame(Title = a$title, Updated = substr(a$updated_at, 1, 16), Drive = ifelse(nzchar(a$drive_synced_at), substr(a$drive_synced_at, 1, 10), "")),
                rownames = FALSE, selection = "single", options = list(dom = "t", pageLength = 20))
    })
    observeEvent(input$done_rows_selected, {
      a <- ans(); a <- a[a$suggestion_id == (input$sid %||% ""), , drop = FALSE][input$done_rows_selected, , drop = FALSE]; req(nrow(a) > 0)
      current(a$analysis_id); instr(a$instructions); updateTextAreaInput(session, "raw", value = a$result_raw)
      parsed(list(title = a$title, summary = a$summary, tables = tables_from_json(a$tables_json),
                  classification = list(country = a$country, category = a$category, topic = a$topic, programme = a$programme),
                  access = split_emails(a$access_emails)))
    })

    # ---- the instructions window ----
    the_instr <- reactive(instr() %||% ctx$settings()$analysis_instructions)
    observeEvent(input$instr, {
      req(ctx$is_owner())
      showModal(modalDialog(title = "Instructions for Claude", size = "l", easyClose = TRUE,
        p(class = "small muted", "Tell Claude what to analyse about this programme or idea. The suggestion, the link and our company profile are added for you."),
        textAreaInput(ns("instr_text"), NULL, the_instr(), rows = 10, width = "100%"),
        layout_columns(col_widths = c(5, 4, 3),
          selectInput(ns("model"), "Model", CLAUDE_MODELS, selected = ctx$settings()$claude_model),
          checkboxInput(ns("web"), "Let Claude check the web page", TRUE),
          checkboxInput(ns("as_default"), "Use as my default", FALSE)),
        footer = tagList(modalButton("Close"),
                         actionButton(ns("instr_save"), "Save instructions", class = "btn-ghost"),
                         actionButton(ns("instr_run"), "Save and run the analysis", class = "btn-brand", icon = icon("robot")))))
    })
    keep_instr <- function() {
      instr(input$instr_text)
      if (isTRUE(input$as_default)) { set_setting("analysis_instructions", input$instr_text, ctx$user()); ctx$bump() }
    }
    observeEvent(input$instr_save, { keep_instr(); removeModal() })
    observeEvent(input$instr_run, { keep_instr(); removeModal(); run_analysis() })
    output$instr_preview <- renderUI(div(class = "small muted", style = "white-space:pre-wrap;margin-top:6px", tags$b("Instructions: "), substr(the_instr(), 1, 400)))

    run_analysis <- function() {
      s <- sug(); req(nrow(s) > 0, ctx$is_owner())
      if (!claude_ready()) return(output$run_status <- renderUI(note("bad", "No Claude API key is set (Admin > Claude API).")))
      model <- input$model %||% ctx$settings()$claude_model
      res <- withProgress(message = "Claude is analysing (this can take a minute)...", tryCatch(
        claude_call(analysis_prompt(s, the_instr(), ctx$settings()$company_profile), system = ANALYSIS_SYSTEM, max_tokens = 8000,
                    web_search = isTRUE(input$web %||% TRUE) && nzchar(s$url), model = model),
        error = function(e) list(error = safe_error_text(e))))
      if (!is.null(res$error)) return(output$run_status <- renderUI(note("bad", res$error)))
      txt <- clean_dashes(res$text)
      updateTextAreaInput(session, "raw", value = txt); current("")
      p <- tryCatch(parse_analysis(txt), error = function(e) list(error = safe_error_text(e)))
      if (!is.null(p$error)) { parsed(NULL); return(output$run_status <- renderUI(note("warn", "Claude answered, but: ", p$error))) }
      p$access <- unique(c(tolower(s$created_by), tolower(ctx$user()))); p$model <- res$model
      parsed(p)
      output$run_status <- renderUI(note("ok", sprintf("Done: %d table(s). Check them, classify, then save.", length(p$tables))))
    }
    observeEvent(input$run, run_analysis())
    observeEvent(input$parse, {
      p <- tryCatch(parse_analysis(clean_dashes(input$raw)), error = function(e) list(error = safe_error_text(e)))
      if (!is.null(p$error)) return(showNotification(p$error, type = "error", duration = 8))
      old <- parsed()
      if (!is.null(old)) { if (!any(nzchar(unlist(p$classification)))) p$classification <- old$classification
                           if (!nzchar(p$title)) p$title <- old$title; if (!nzchar(p$summary)) p$summary <- old$summary; p$access <- old$access }
      if (is.null(p$access)) p$access <- unique(c(tolower(sug()$created_by), tolower(ctx$user())))
      parsed(p); showNotification(sprintf("Parsed %d table(s).", length(p$tables)), type = "message")
    })
    output$parsed <- renderUI({
      p <- parsed(); req(p)
      tagList(tags$hr(), if (nzchar(p$summary %||% "")) p(p$summary), render_tables(p$tables))
    })

    # ---- save, classify, access, Drive ----
    output$save_box <- renderUI({
      p <- parsed(); req(p, ctx$is_owner())
      a <- ans(); u <- get_users(); ppl <- ctx$data$people()
      emails <- sort(unique(c(tolower(u$email), ppl$email[nzchar(ppl$email)], p$access)))
      opts <- function(k) sort(unique(c(a[[k]][nzchar(a[[k]])], p$classification[[k]])))
      cl <- p$classification
      card("4. Classify, share and save",
        layout_columns(col_widths = c(6, 6),
          textInput(ns("t_title"), "Title", p$title %|% sug()$title, width = "100%"),
          textInput(ns("t_summary"), "Summary", p$summary %||% "", width = "100%")),
        p(class = "small muted", "Classification (Country > Category > Topic > Programme). Choose an existing value to keep the tree tidy, or type a new one."),
        do.call(layout_columns, c(list(col_widths = c(3, 3, 3, 3)),
          lapply(names(HIERARCHY), function(k) selectizeInput(ns(paste0("c_", k)), HIERARCHY[[k]], choices = opts(k), selected = cl[[k]] %||% "",
                                                               options = list(create = TRUE, placeholder = "Type or choose"))))),
        selectizeInput(ns("access"), "Who can see these tables (the person who made the suggestion is always included)", choices = emails,
                       selected = p$access, multiple = TRUE, width = "100%", options = list(create = TRUE)),
        div(class = "btn-row",
            actionButton(ns("save"), if (nzchar(current())) "Save changes" else "Save analysis", class = "btn-brand", icon = icon("floppy-disk")),
            actionButton(ns("to_drive"), "Save and upload to Google Drive", class = "btn-ghost", icon = icon("cloud-arrow-up"))),
        uiOutput(ns("save_status")))
    })
    save_analysis <- function() {
      p <- parsed(); s <- sug(); req(p, nrow(s) > 0, ctx$is_owner())
      access <- unique(c(tolower(s$created_by), split_emails(input$access)))
      old <- ans(); old <- old[old$analysis_id == current(), , drop = FALSE]
      raw <- input$raw %||% ""; tj <- tables_to_json(p$tables)
      if (nchar(tj) > CELL_LIMIT) showNotification("These tables are very long; the Google Sheet may cut them. The Drive copy keeps them whole.", type = "warning", duration = 10)
      row <- data.frame(analysis_id = current() %|% new_id("an"), suggestion_id = s$suggestion_id, title = clean_dashes(input$t_title %|% s$title),
        instructions = the_instr(), model = p$model %||% (old$model[1] %||% ""), result_raw = substr(raw, 1, CELL_LIMIT), tables_json = tj,
        summary = clean_dashes(input$t_summary %||% ""), country = input$c_country %||% "", category = input$c_category %||% "",
        topic = input$c_topic %||% "", programme = input$c_programme %||% "", access_emails = paste(access, collapse = ", "),
        status = "saved", created_by = old$created_by[1] %||% tolower(ctx$user()), created_at = old$created_at[1] %||% now_ts(),
        updated_at = now_ts(), drive_id = old$drive_id[1] %||% "", drive_path = old$drive_path[1] %||% "",
        drive_synced_at = old$drive_synced_at[1] %||% "", deleted = "FALSE", stringsAsFactors = FALSE)
      store_append("analyses", row, user = ctx$user())
      if (s$status != "analysed") { s$status <- "analysed"; s$updated_at <- now_ts(); store_append("suggestions", s, user = ctx$user()) }
      # keep what was typed when the form is drawn again
      parsed(modifyList(p, list(title = row$title, summary = row$summary, access = access,
                                classification = list(country = row$country, category = row$category, topic = row$topic, programme = row$programme))))
      current(row$analysis_id); ctx$bump(); row
    }
    observeEvent(input$save, { save_analysis(); output$save_status <- renderUI(note("ok", "Saved. It is in Analysis library for the people listed.")) })
    observeEvent(input$to_drive, {
      row <- save_analysis()
      r <- withProgress(message = "Uploading to Google Drive...", tryCatch(drive_save_analysis(row, ctx$settings()), error = function(e) list(error = safe_error_text(e))))
      if (!is.null(r$error)) return(output$save_status <- renderUI(note("bad", "Saved in the app, but not on Drive: ", r$error)))
      row$drive_id <- r$id; row$drive_path <- r$path; row$drive_synced_at <- now_ts(); row$updated_at <- now_ts()
      store_append("analyses", row, user = ctx$user(), log = FALSE); ctx$bump()
      output$save_status <- renderUI(note("ok", "Saved and uploaded to Google Drive: ", r$path))
    })
  })
}
