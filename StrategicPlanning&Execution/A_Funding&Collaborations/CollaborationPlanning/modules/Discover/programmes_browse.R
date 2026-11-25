# ---- module ----------------------------------------------
# id:           programmes_browse
# name:         Programmes
# icon:         table
# description:  Browse all programmes, re-check one at source, move it to another stage, download, or add a CSV
# packages:     shiny, DT
# -----------------------------------------------------------

programmes_browse_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card(NULL,
      layout_columns(col_widths = c(3, 3, 3, 3),
        selectInput(ns("f_stage"), "Stage", c("All", STAGES)),
        selectInput(ns("f_category"), "Category", "All"),
        selectInput(ns("f_country"), "Country", "All"),
        div(class = "align-bottom", downloadButton(ns("download"), "Download CSV", class = "btn-ghost sm")))),
    card(NULL, DTOutput(ns("table"))),
    uiOutput(ns("detail")),
    uiOutput(ns("recheck")),
    uiOutput(ns("csv_box")))
}

programmes_browse_csv_card <- function(ns) {
  card("Add programmes from a CSV file",
      p(class = "small muted", "Columns are matched by name to the programme fields (for example programme_name, funder, ",
        "category, country, amount_text, closes_date, verified_urls). The old Funding Programmes and Grant Compass ",
        "column names are also understood. Rows already in the list (same funder and name) are skipped."),
      fileInput(ns("csv"), NULL, accept = ".csv", buttonLabel = "Choose CSV"),
      uiOutput(ns("csv_status")))
}

programmes_browse_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    shown_cols <- c("programme_name", "funder", "category", "country", "amount_text", "closes_date", "deadline_text", "stage")

    output$csv_box <- renderUI(if (!ctx$is_partner()) programmes_browse_csv_card(ns))
    observe({
      p <- ctx$programmes()
      updateSelectInput(session, "f_category", choices = c("All", sort(unique(p$category[nzchar(p$category)]))),
                        selected = isolate(input$f_category))
      updateSelectInput(session, "f_country", choices = c("All", sort(unique(p$country[nzchar(p$country)]))),
                        selected = isolate(input$f_country))
    })

    filtered <- reactive({
      p <- ctx$programmes()
      st <- ctx$status()
      p$fit <- st$fit$fit[match(p$programme_id, st$fit$programme_id)]
      p$elig <- st$elig$status[match(p$programme_id, st$elig$programme_id)]
      p$elig[is.na(p$elig)] <- "unchecked"
      if (!identical(input$f_stage, "All")) p <- p[p$stage == input$f_stage, , drop = FALSE]
      if (!is.null(input$f_category) && input$f_category != "All") p <- p[p$category == input$f_category, , drop = FALSE]
      if (!is.null(input$f_country) && input$f_country != "All") p <- p[p$country == input$f_country, , drop = FALSE]
      p
    })

    output$table <- renderDT({
      d <- filtered()[, c(shown_cols, "fit", "elig"), drop = FALSE]
      names(d) <- c("Programme", "Funder", "Category", "Country", "Amount", "Closes", "Deadline note", "Stage", "Fit", "Eligibility")
      datatable(d, rownames = FALSE, selection = "single", filter = "none",
                options = list(pageLength = 15, scrollX = TRUE, dom = "ftip"))
    })

    picked <- reactive({
      i <- input$table_rows_selected
      if (!length(i)) return(NULL)
      filtered()[i, , drop = FALSE]
    })

    output$detail <- renderUI({
      r <- picked(); req(r)
      field <- function(label, v) if (nzchar(v)) tags$tr(tags$th(label), tags$td(v))
      links <- strsplit(r$verified_urls, "[,\n ]+")[[1]]
      links <- links[grepl("^https?://", links)]
      card(r$programme_name,
        if (is_true(r$is_example)) example_badge(),
        elig_badge(r$elig), fit_badge(r$fit),
        if (!nzchar(r$verified_at)) note("warn", "Not checked at source yet. Confirm amounts and dates on the funder's site.")
        else if (difftime(Sys.time(), as.POSIXct(r$verified_at), units = "days") > num(ctx$settings()$verify_days))
          note("warn", "Last checked more than ", ctx$settings()$verify_days, " days ago: check at source."),
        tags$table(class = "kv",
          field("Funder", r$funder), field("Category", r$category),
          field("Where", paste(c(r$country, r$city_region)[nzchar(c(r$country, r$city_region))], collapse = ", ")),
          field("Amount", r$amount_text), field("Opens", r$opens_date), field("Closes", r$closes_date),
          field("Deadline note", r$deadline_text), field("Conditions", r$conditions),
          field("Areas", r$themes), field("Sponsors", r$key_sponsors), field("Tips", r$recommendations),
          field("Source", r$source), field("Last checked", r$verified_at)),
        if (length(links)) p(lapply(links, function(u) tags$a(href = u, target = "_blank", rel = "noopener", class = "link-chip", u))),
        if (!ctx$is_partner()) div(class = "btn-row",
            selectInput(ns("new_stage"), "Move to stage", STAGES, selected = if (r$stage %in% STAGES) r$stage else "Discover", width = "220px"),
            actionButton(ns("save_stage"), "Save stage", class = "btn-brand"),
            actionButton(ns("recheck_go"), "Re-check at source", class = "btn-ghost", icon = icon("rotate"))))
    })

    observeEvent(input$save_stage, {
      r <- picked(); req(r, !ctx$is_partner())
      res <- move_programme_stage(r$programme_id, input$new_stage, ctx$user())
      ctx$bump()
      showNotification(res$msg, type = if (res$ok) "message" else "error", duration = if (res$ok) 4 else 10)
    })

    # ---- re-check at source: Claude reads the source page and we show what changed ----
    check <- reactiveVal(NULL)
    observeEvent(input$table_rows_selected, check(NULL), ignoreNULL = FALSE)
    observeEvent(input$recheck_go, {
      r <- picked(); req(r)
      url <- r$source_url %|% strsplit(r$verified_urls, "[, ]+")[[1]][1] %|% ""
      if (!claude_ready()) return(check(list(error = "No Claude API key is set (Admin > Claude API).")))
      prompt <- paste0("Check this funding programme against its live web page", if (nzchar(url)) paste0(" (", url, ")"), ".\n",
        "Programme: ", r$programme_name, ". Funder: ", r$funder, ".\n",
        "Use web search to open the official page. Reply with JSON only, no other words:\n",
        '{"found": true or false, "status": "open" or "closed" or "upcoming" or "unknown", "amount_text": "...", ',
        '"min_gbp": number or null, "max_gbp": number or null, "funding_rate_pct": number or null, ',
        '"opens_date": "YYYY-MM-DD" or "", "closes_date": "YYYY-MM-DD" or "", "deadline_text": "...", ',
        '"source_url": "page you read", "notes": "one sentence on anything that changed"}\n',
        "Use empty strings or null for anything the page does not state. Never guess.")
      res <- withProgress(message = "Checking the funder's page...", tryCatch(claude_json(prompt, max_tokens = 2500, web_search = TRUE),
                          error = function(e) list(error = safe_error_text(e))))
      check(c(list(pid = r$programme_id), res))
    })
    output$recheck <- renderUI({
      ck <- check(); req(ck)
      if (!is.null(ck$error)) return(note("bad", ck$error))
      r <- picked(); req(r, identical(r$programme_id, ck$pid))
      if (!isTRUE(ck$found)) return(note("warn", "Claude could not find the programme's page. ", ck$notes %||% ""))
      f <- c(amount_text = "Amount", min_gbp = "Minimum (GBP)", max_gbp = "Maximum (GBP)", funding_rate_pct = "Funding rate (%)",
             opens_date = "Opens", closes_date = "Closes", deadline_text = "Deadline note", source_url = "Source")
      rows <- lapply(names(f), function(k) {
        new <- as.character(ck[[k]] %||% ""); if (identical(new, "NA")) new <- ""
        old <- as.character(r[[k]] %||% "")
        tags$tr(class = if (nzchar(new) && !identical(trimws(new), trimws(old))) "changed",
                tags$th(f[[k]]), tags$td(old), tags$td(if (nzchar(new) && !identical(trimws(new), trimws(old))) tags$b(new) else new))
      })
      card("What the funder's page says now",
        p("Status on the page: ", tags$b(ck$status %||% "unknown"), ". ", ck$notes %||% ""),
        tags$table(class = "qs-table", tags$thead(tags$tr(tags$th(""), tags$th("In the app"), tags$th("On the page"))), tags$tbody(rows)),
        div(class = "btn-row", actionButton(ns("accept"), "Accept and mark as checked", class = "btn-brand"),
            actionButton(ns("dismiss"), "Dismiss", class = "btn-ghost")))
    })
    observeEvent(input$dismiss, check(NULL))
    observeEvent(input$accept, {
      ck <- check(); req(ck, is.null(ck$error))
      upd <- list(verified_at = now_ts(), verified_by = "Claude web search")
      for (k in c("amount_text", "min_gbp", "max_gbp", "funding_rate_pct", "opens_date", "closes_date", "deadline_text", "source_url")) {
        v <- as.character(ck[[k]] %||% ""); if (nzchar(v) && v != "NA") upd[[k]] <- if (k %in% c("min_gbp", "max_gbp")) format(num(v), scientific = FALSE) else v
      }
      if (identical(ck$status, "closed")) upd$deadline_text <- paste("Closed (checked", format(Sys.Date()), ")")
      ok <- update_programme_fields(ck$pid, upd, ctx$user(), "re-checked at source")
      check(NULL); ctx$bump()
      showNotification(if (ok) "Updated and marked as checked." else "Could not save.", type = if (ok) "message" else "error")
    })

    output$download <- downloadHandler(
      filename = function() paste0("programmes_", format(Sys.Date(), "%Y%m%d"), ".csv"),
      content = function(file) utils::write.csv(filtered(), file, row.names = FALSE))

    observeEvent(input$csv, {
      req(!ctx$is_partner())
      res <- tryCatch({
        raw <- utils::read.csv(input$csv$datapath, stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE)
        add_programmes(map_programme_columns(raw, source = "CSV upload"), ctx$user())
      }, error = function(e) list(added = 0, skipped = 0, error = safe_error_text(e)))
      output$csv_status <- renderUI(
        if (!is.null(res$error)) note("bad", res$error)
        else note("ok", sprintf("Added %d programme(s); skipped %d already in the list.", res$added, res$skipped)))
      ctx$bump()
    })
  })
}
