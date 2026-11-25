# ---- module ----------------------------------------------
# id:           risk_register
# name:         Risk register
# icon:         triangle-exclamation
# description:  Risks per project scored likelihood x impact, sorted and coloured by score
# packages:     shiny, DT
# -----------------------------------------------------------
# From the FMEA / risk idea in BooksNetworks StrategySixS (Six Sigma Analysis): score = likelihood x impact (1 to 25).

risk_register_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card(NULL, selectInput(ns("proj"), "Project", NULL, width = "100%")),
    uiOutput(ns("summary")),
    card("Risks", DTOutput(ns("table")), uiOutput(ns("edit_btns"))),
    card(textOutput(ns("form_title"), inline = TRUE),
      textInput(ns("risk"), "Risk", width = "100%"),
      layout_columns(col_widths = c(6, 6), textInput(ns("cause"), "Cause", width = "100%"), textInput(ns("effect"), "Effect", width = "100%")),
      layout_columns(col_widths = c(3, 3, 3, 3),
        sliderInput(ns("lik"), "Likelihood", 1, 5, 3, step = 1), sliderInput(ns("imp"), "Impact", 1, 5, 3, step = 1),
        selectInput(ns("owner"), "Owner", NULL), selectInput(ns("status"), "Status", c("open", "reducing", "closed"))),
      textAreaInput(ns("mit"), "What we do about it", rows = 2, width = "100%"),
      div(class = "btn-row", actionButton(ns("save"), "Save risk", class = "btn-brand"),
          actionButton(ns("new"), "New risk", class = "btn-ghost"),
          actionButton(ns("suggest"), "Suggest risks with Claude", class = "btn-ghost", icon = icon("robot"))),
      uiOutput(ns("suggestions"))))
}

risk_register_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    editing <- reactiveVal("")
    output$form_title <- renderText(if (nzchar(editing())) "Edit risk" else "Add a risk")
    observe({ ch <- project_picker_choices(ctx); updateSelectInput(session, "proj", choices = ch, selected = pick_sel(isolate(input$proj), ch, ctx$handoff$project)) })
    proj <- reactive({ pr <- ctx$data$projects(); pr[pr$project_id == (input$proj %||% ""), , drop = FALSE] })
    observe({ r <- proj(); req(nrow(r) > 0); updateSelectInput(session, "owner", choices = c("(nobody)" = "", project_people(r$programme_id, ctx$data$consortium()))) })
    risks <- reactive({
      x <- latest_by(ctx$table("risks")(), "risk_id"); x <- x[x$project_id == (input$proj %||% "") & x$status != "deleted", , drop = FALSE]
      x$score <- num(x$likelihood) * num(x$impact); x[order(-x$score), , drop = FALSE]
    })
    output$summary <- renderUI({
      if (!length(project_picker_choices(ctx))) return(project_empty_note())
      x <- risks(); req(nrow(x) > 0); o <- x[x$status != "closed", , drop = FALSE]
      note(if (any(o$score >= 15)) "bad" else if (any(o$score >= 8)) "warn" else "ok",
           sprintf("%d open risk(s): %d high (15 or more), %d medium (8 to 14).", nrow(o), sum(o$score >= 15), sum(o$score >= 8 & o$score < 15)))
    })
    output$table <- renderDT({
      x <- risks()
      d <- data.frame(Score = x$score, Risk = x$risk, Cause = x$cause, Effect = x$effect, L = x$likelihood, I = x$impact,
                      Owner = x$owner_email, Mitigation = x$mitigation, Status = x$status)
      datatable(d, rownames = FALSE, selection = "single", options = list(dom = "tip", pageLength = 15, scrollX = TRUE)) |>
        formatStyle("Score", backgroundColor = styleInterval(c(7.5, 14.5), c("#d9f2e6", "#fbecc4", "#f8d0de")), fontWeight = "bold")
    })
    output$edit_btns <- renderUI(if (length(input$table_rows_selected) && !ctx$is_partner())
      div(class = "btn-row", actionButton(ns("edit"), "Edit selected", class = "btn-ghost sm"), actionButton(ns("del"), "Delete selected", class = "btn-ghost sm")))
    observeEvent(input$edit, {
      r <- risks()[input$table_rows_selected, , drop = FALSE]; req(nrow(r) > 0); editing(r$risk_id)
      for (f in c("risk", "cause", "effect")) updateTextInput(session, f, value = r[[f]])
      updateSliderInput(session, "lik", value = num(r$likelihood)); updateSliderInput(session, "imp", value = num(r$impact))
      updateSelectInput(session, "owner", selected = r$owner_email); updateSelectInput(session, "status", selected = r$status)
      updateTextAreaInput(session, "mit", value = r$mitigation)
    })
    clear <- function() { editing(""); for (f in c("risk", "cause", "effect", "mit")) updateTextInput(session, f, value = "") }
    observeEvent(input$new, clear())
    save_risk <- function(id, f) store_append("risks", data.frame(risk_id = id, project_id = input$proj, risk = f$risk, cause = f$cause %||% "",
      effect = f$effect %||% "", likelihood = f$lik, impact = f$imp, owner_email = f$owner %||% "", mitigation = f$mit %||% "",
      status = f$status %||% "open", updated_at = now_ts(), updated_by = ctx$user(), stringsAsFactors = FALSE), user = ctx$user())
    observeEvent(input$save, {
      req(proj(), !ctx$is_partner()); if (blank(input$risk)) return(showNotification("Describe the risk.", type = "warning"))
      save_risk(editing() %|% new_id("risk"), list(risk = input$risk, cause = input$cause, effect = input$effect, lik = input$lik,
                imp = input$imp, owner = input$owner, mit = input$mit, status = input$status))
      clear(); ctx$bump(); showNotification("Risk saved.", type = "message")
    })
    observeEvent(input$del, {
      r <- risks()[input$table_rows_selected, , drop = FALSE]; req(nrow(r) > 0, !ctx$is_partner()); r$status <- "deleted"; r$updated_at <- now_ts()
      store_append("risks", r[, SCHEMAS$risks], user = ctx$user()); ctx$bump()
    })
    sugg <- reactiveVal(NULL)
    observeEvent(input$suggest, {
      r <- proj(); req(nrow(r) > 0); if (!claude_ready()) return(showNotification("No Claude API key is set.", type = "error"))
      p <- ctx$programmes(); pr <- p[p$programme_id == r$programme_id, , drop = FALSE]
      t <- ctx$data$tasks(); t <- t[t$project_id == r$project_id, , drop = FALSE]
      prompt <- paste0("List the 6 most important delivery risks for this funded project. Reply with JSON only: an array of ",
        '{"risk": "", "cause": "", "effect": "", "likelihood": 1-5, "impact": 1-5, "mitigation": ""}.\n',
        "Project: ", r$title, ". Programme: ", pr$programme_name[1] %||% "", ". ", pr$summary[1] %||% "",
        "\nWork packages and tasks: ", paste(unique(paste(t$work_package, t$task, sep = ": ")), collapse = "; "),
        "\nExisting risks (do not repeat): ", paste(risks()$risk, collapse = "; "))
      res <- withProgress(message = "Thinking about risks...", tryCatch(as.data.frame(claude_json(prompt, max_tokens = 2000)), error = function(e) safe_error_text(e)))
      sugg(res)
    })
    output$suggestions <- renderUI({
      s <- sugg(); req(s)
      if (is.character(s)) return(note("bad", s))
      tagList(tags$hr(), checkboxGroupInput(ns("pick"), "Suggested risks: tick the ones to add",
        choiceNames = sprintf("%s (L%s x I%s): %s", s$risk, s$likelihood, s$impact, s$mitigation), choiceValues = as.character(seq_len(nrow(s)))),
        actionButton(ns("add_sugg"), "Add ticked risks", class = "btn-brand sm"))
    })
    observeEvent(input$add_sugg, {
      s <- sugg(); req(is.data.frame(s), length(input$pick), !ctx$is_partner())
      for (i in as.integer(input$pick)) save_risk(new_id("risk"), list(risk = s$risk[i], cause = s$cause[i], effect = s$effect[i],
        lik = max(1, min(5, num(s$likelihood[i]))), imp = max(1, min(5, num(s$impact[i]))), mit = s$mitigation[i], status = "open"))
      sugg(NULL); ctx$bump(); showNotification("Risks added.", type = "message")
    })
  })
}
