# ---- module ----------------------------------------------
# id:           eligibility_check
# name:         Eligibility check
# icon:         clipboard-check
# description:  Split a programme's conditions, check each against the company profile, override, and save
# packages:     shiny
# -----------------------------------------------------------
# Any condition "not met" marks the programme ineligible: a red badge everywhere, and it cannot move to Decide.

eligibility_check_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("profile_note")),
    card(NULL,
      layout_columns(col_widths = c(8, 4),
        selectInput(ns("pid"), "Programme (Discover or Qualify stage)", NULL, width = "100%"),
        div(class = "align-bottom", uiOutput(ns("badge"))))),
    uiOutput(ns("conditions_box")),
    uiOutput(ns("results")))
}

eligibility_check_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    rows <- reactiveVal(NULL)   # data frame: condition, result, evidence

    observe({
      ch <- programme_choices(ctx$programmes(), c("Discover", "Qualify"))
      updateSelectInput(session, "pid", choices = ch, selected = pick_sel(isolate(input$pid), ch))
    })
    prog <- reactive({ p <- ctx$programmes(); p[p$programme_id == (input$pid %||% ""), , drop = FALSE] })

    output$profile_note <- renderUI({
      if (!nzchar(trimws(ctx$settings()$company_profile)))
        note("warn", "No company profile is set, so Claude has nothing to compare against. An admin can add it in Admin > General settings. ",
             "You can still set each result by hand.")
    })
    output$badge <- renderUI({ req(input$pid); elig_badge(elig_status_of(input$pid, ctx$status()$elig)) %||% span(class = "pill pill-off", "Not checked") })

    # load the saved results (or the split conditions) when the programme changes
    observeEvent(list(input$pid, ctx$data$eligibility()), {
      req(input$pid)
      e <- latest_by(ctx$data$eligibility(), c("programme_id", "condition"), "checked_at")
      e <- e[e$programme_id == input$pid, , drop = FALSE]
      if (nrow(e)) rows(e[, c("condition", "result", "evidence")]) else rows(NULL)
    })

    output$conditions_box <- renderUI({
      r <- prog(); req(nrow(r) > 0)
      card("Conditions",
        p(class = "small muted", "From the programme record. Edit them here if needed: one condition per line."),
        textAreaInput(ns("conds"), NULL, value = gsub("\\s*;\\s*", "\n", r$conditions), rows = 5, width = "100%"),
        div(class = "btn-row",
            actionButton(ns("split"), "Split into conditions", class = "btn-ghost"),
            actionButton(ns("check"), "Check with Claude", class = "btn-brand", icon = icon("robot"))),
        uiOutput(ns("check_status")))
    })

    split_conds <- function() {
      v <- trimws(unlist(strsplit(input$conds %||% "", "[;\n]+|\\.\\s+(?=[A-Z])", perl = TRUE)))
      v <- sub("^[-*•]+\\s*", "", v)
      unique(v[nchar(v) > 2])
    }
    observeEvent(input$split, {
      v <- split_conds()
      if (!length(v)) return(showNotification("No conditions to split.", type = "warning"))
      rows(data.frame(condition = v, result = "unclear", evidence = "", stringsAsFactors = FALSE))
    })
    observeEvent(input$check, {
      v <- split_conds()
      if (!length(v)) return(output$check_status <- renderUI(note("warn", "Add the conditions first.")))
      if (!claude_ready()) return(output$check_status <- renderUI(note("bad", "No Claude API key is set. Use Split, then set each result by hand.")))
      r <- prog()
      prompt <- paste0("Compare each eligibility condition of a funding programme with our company profile.\n\n",
        "Programme: ", r$programme_name, " (", r$funder, ", ", r$country, ")\n\nCompany profile:\n", ctx$settings()$company_profile,
        "\n\nConditions:\n", paste0("- ", v, collapse = "\n"),
        "\n\nReply with JSON only: an array with one object per condition, in the same order: ",
        '[{"condition": "...", "result": "met" or "unclear" or "not met", "evidence": "one short line from the profile, or what is missing"}]. ',
        "Use \"unclear\" when the profile does not say. Plain British English.")
      res <- withProgress(message = "Checking each condition...", tryCatch(claude_json(prompt, max_tokens = 2500),
                          error = function(e) list(error = safe_error_text(e))))
      if (is.list(res) && !is.data.frame(res) && !is.null(res$error)) return(output$check_status <- renderUI(note("bad", res$error)))
      d <- as.data.frame(res, stringsAsFactors = FALSE)
      if (!all(c("condition", "result") %in% names(d))) return(output$check_status <- renderUI(note("bad", "Claude's reply was not in the expected form. Try again.")))
      d$result <- tolower(trimws(d$result)); d$result[!d$result %in% c("met", "unclear", "not met")] <- "unclear"
      d$evidence <- as.character(d$evidence %||% "")
      rows(d[, c("condition", "result", "evidence")])
      output$check_status <- renderUI(note("ok", "Checked. Review each result, change any that are wrong, then save."))
    })

    output$results <- renderUI({
      d <- rows(); req(d, nrow(d) > 0)
      card("Results",
        p(class = "small muted", "You can override each result. Any \"not met\" marks the programme ineligible."),
        tags$table(class = "qs-table", tags$thead(tags$tr(tags$th("Condition"), tags$th("Result"), tags$th("Evidence"))),
          tags$tbody(lapply(seq_len(nrow(d)), function(i) tags$tr(
            tags$td(d$condition[i]),
            tags$td(style = "width:150px", selectInput(ns(paste0("res_", i)), NULL, c("met", "unclear", "not met"), d$result[i])),
            tags$td(textInput(ns(paste0("ev_", i)), NULL, d$evidence[i], width = "100%")))))),
        actionButton(ns("save"), "Save results", class = "btn-brand", icon = icon("floppy-disk")))
    })

    observeEvent(input$save, {
      d <- rows(); req(d, input$pid)
      out <- data.frame(programme_id = input$pid, condition = d$condition,
        result = vapply(seq_len(nrow(d)), function(i) input[[paste0("res_", i)]] %||% d$result[i], ""),
        evidence = vapply(seq_len(nrow(d)), function(i) input[[paste0("ev_", i)]] %||% d$evidence[i], ""),
        checked_by = ctx$user(), checked_at = now_ts(), stringsAsFactors = FALSE)
      # conditions that were dropped from the list are closed off so they no longer count
      old <- latest_by(store_read("eligibility", fresh = TRUE), c("programme_id", "condition"), "checked_at")
      gone <- setdiff(old$condition[old$programme_id == input$pid & old$result != "removed"], out$condition)
      if (length(gone)) out <- rbind(out, data.frame(programme_id = input$pid, condition = gone, result = "removed", evidence = "",
                                                     checked_by = ctx$user(), checked_at = now_ts(), stringsAsFactors = FALSE))
      store_append("eligibility", out, user = ctx$user())
      p <- prog()
      if (nrow(p) && p$stage == "Discover") move_programme_stage(input$pid, "Qualify", ctx$user())
      ctx$bump()
      bad <- sum(out$result == "not met")
      showNotification(if (bad) sprintf("Saved. %d condition(s) not met: the programme is marked ineligible.", bad) else "Saved.",
                       type = if (bad) "warning" else "message")
    })
  })
}
