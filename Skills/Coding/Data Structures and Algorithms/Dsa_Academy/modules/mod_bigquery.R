# modules/mod_bigquery.R — APIs › BigQuery: connect with a service-account key, see the tables, sync status and log.

bigquery_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🗄️", "BigQuery",
      "All progress — submissions, drafts, time on task, reviews, quizzes, mock interviews, practice rounds, STAR stories, settings and export history — is stored in Google BigQuery. Connect once with a service-account key; missing tables are created for you.",
      c("Service-account key", "One dataset", "14 tables, prefix dsa_", "CREATE TABLE IF NOT EXISTS", "Never drops data", "Auto-sync")),
    uiOutput(ns("banner")),
    fluidRow(
      box(title = "Connection", status = "primary", solidHeader = TRUE, width = 7,
        fluidRow(
          column(6,
            fileInput(ns("key_file"), "Service-account key (.json)", accept = ".json", width = "100%"),
            textAreaInput(ns("key_text"), "…or paste the JSON", "", rows = 4, width = "100%", placeholder = '{"type": "service_account", ...}')),
          column(6,
            textInput(ns("project"), "Project ID", .bq$project, width = "100%"),
            textInput(ns("dataset"), "Dataset ID", .bq$dataset, width = "100%"),
            fluidRow(column(6, textInput(ns("prefix"), "Table prefix", .bq$prefix, width = "100%")),
                     column(6, textInput(ns("location"), "Location (new dataset only)", .bq$location, width = "100%", placeholder = "US / EU / europe-west2"))))),
        tags$div(style = "display:flex; gap:6px; flex-wrap:wrap;",
          actionButton(ns("connect"), "Connect to BigQuery", icon = icon("plug"), class = "btn btn-dsa"),
          actionButton(ns("sync"), "Sync now", icon = icon("rotate"), class = "btn btn-dsa-outline"),
          actionButton(ns("reload"), "Reload from BigQuery", icon = icon("download"), class = "btn btn-dsa-outline"),
          actionButton(ns("disconnect"), "Disconnect", class = "btn btn-dsa-outline")),
        uiOutput(ns("result")),
        tags$hr(),
        tags$div(class = "code-title", "Connecting automatically"),
        tags$p(style = "font-size:13px;", HTML(paste0(
          "When the app starts it looks for a key in this order and connects without asking:<br>",
          "1. any service-account <code>*.json</code> in <code>C:/111_SecA/_q_api</code> on Windows, or in the folder named by <code>LAT_CRED_DIR</code> ",
          "(a key whose <code>project_id</code> matches the project wins, otherwise the newest);<br>",
          "2. the file named by <code>DSA_BQ_KEY_FILE</code>, <code>ATERA_BQ_KEY_FILE</code> or <code>GOOGLE_APPLICATION_CREDENTIALS</code>.<br>",
          "Override the defaults with <code>DSA_BQ_PROJECT</code>, <code>DSA_BQ_DATASET</code>, <code>DSA_BQ_PREFIX</code> and <code>DSA_BQ_LOCATION</code>. ",
          "Keys are only read — never copied, stored in BigQuery or printed.")))),
      box(title = "What the service account needs", status = "info", solidHeader = TRUE, width = 5,
        tags$ul(style = "font-size:13px;",
          tags$li(tags$b("BigQuery Job User"), " on the project (to run queries)."),
          tags$li(tags$b("BigQuery Data Editor"), " on the dataset (to create tables and write rows)."),
          tags$li("To let the app create the dataset itself, ", tags$b("BigQuery Data Editor"), " or ", tags$b("BigQuery User"), " on the project.")),
        callout("Each sync is <b>one multi-statement transaction</b> (BEGIN … COMMIT) containing all changes since the last one, sent a few seconds after you act, when you close the tab, and when the app stops. Reads come from memory, so pages never wait for BigQuery.", "tip"),
        callout("Connecting runs <code>CREATE TABLE IF NOT EXISTS</code> for missing tables and <code>ALTER TABLE … ADD COLUMN IF NOT EXISTS</code> for missing columns. Existing tables and rows are never dropped or rewritten.", "info"))
    ),
    fluidRow(
      box(title = "Tables", status = "primary", solidHeader = TRUE, width = 12,
        DT::DTOutput(ns("tables")),
        fluidRow(
          column(4, selectInput(ns("test_table"), "Preview a table straight from BigQuery", names(BQ_SCHEMA), width = "100%")),
          column(3, tags$div(style = "margin-top:25px;", actionButton(ns("test"), "Top 5 rows", icon = icon("table"), class = "btn btn-dsa-outline btn-sm")))),
        DT::DTOutput(ns("test_out")),
        tags$details(tags$summary("Table definitions (DDL)"), uiOutput(ns("ddl"))))
    ),
    fluidRow(
      box(title = "Activity log", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE,
        uiOutput(ns("log")))
    )
  )
}

bigquery_server <- function(id, progress = NULL, bus = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    rv <- reactiveValues(msg = NULL, test = NULL, tick = 0)
    bump <- function() { rv$tick <- rv$tick + 1; if (!is.null(bus)) bus$db_tick <- (isolate(bus$db_tick) %||% 0) + 1 }

    output$banner <- renderUI({
      rv$tick; invalidateLater(3000); s <- bq_state()
      if (!bq_available()) return(callout("<b>The bigrquery package is not installed.</b> Run <code>install.packages(\"bigrquery\")</code> and restart the app.", "warn"))
      if (s$ready) callout(sprintf("<b>Connected</b> to <code>%s</code> as <code>%s</code>%s. %s%s", s$where, htmltools::htmlEscape(s$email),
                                   if (nzchar(s$source)) paste0(" — ", htmltools::htmlEscape(s$source)) else "",
                                   if (s$pending) sprintf("%d change(s) waiting to be written. ", s$pending) else "All changes are saved. ",
                                   if (!is.na(s$last_sync)) sprintf("Last sync %s.", format(s$last_sync, "%H:%M:%S")) else ""), "success")
      else callout(sprintf("<b>Not connected.</b> %s Progress you make now is kept in memory (%d change(s)) and written to BigQuery as soon as you connect.%s",
                           switch(s$status, "no key" = "No key was found automatically.", failed = "The last connection attempt failed.", ""),
                           s$pending, if (nzchar(s$last_error)) paste0("<br><small>", htmltools::htmlEscape(s$last_error), "</small>") else ""), "warn")
    })

    observeEvent(input$connect, {
      path <- input$key_file$datapath %||% NULL; txt <- input$key_text %||% ""
      if (is.null(path) && !nzchar(trimws(txt))) {
        k <- bq_find_key()
        if (is.null(k)) { rv$msg <- list(ok = FALSE, text = "Upload or paste a service-account key first."); return() }
        path <- k$path; src <- paste("with", k$source)
      } else src <- if (!is.null(path)) paste("with the uploaded key", input$key_file$name) else "with the pasted key"
      withProgress(message = "Connecting to BigQuery…", value = 0.3, {
        res <- tryCatch(bq_connect(json_path = path, json_text = if (is.null(input$key_file)) txt else NULL,
                                   project = trimws(input$project), dataset = trimws(input$dataset), prefix = trimws(input$prefix),
                                   location = trimws(input$location), source = paste("connected by hand", src)),
                        error = function(e) e)
      })
      rv$msg <- if (inherits(res, "error")) list(ok = FALSE, text = conditionMessage(res))
                else list(ok = TRUE, text = sprintf("Connected. %s%s Loaded %d table(s) into memory.",
                                                    if (length(res$created)) sprintf("Created %d new table(s): %s. ", length(res$created), paste(res$created, collapse = ", ")) else "All tables already existed. ",
                                                    if (length(res$added)) sprintf("Added column(s): %s. ", paste(res$added, collapse = ", ")) else "", length(BQ_SCHEMA)))
      updateTextAreaInput(session, "key_text", value = "")
      bump()
    })
    observeEvent(input$sync, {
      if (!bq_state()$ready) { rv$msg <- list(ok = FALSE, text = "Connect first."); return() }
      ok <- bq_flush("by hand"); rv$msg <- list(ok = ok, text = if (ok) "Everything is saved in BigQuery." else paste("Sync failed:", .bq$last_error)); bump()
    })
    observeEvent(input$reload, {
      if (!bq_state()$ready) { rv$msg <- list(ok = FALSE, text = "Connect first."); return() }
      bq_flush("before reload"); ok <- bq_load_all()
      rv$msg <- list(ok = ok, text = if (ok) "Reloaded every table from BigQuery." else paste("Reload failed:", .bq$last_error)); bump()
    })
    observeEvent(input$disconnect, { bq_disconnect(); rv$msg <- list(ok = TRUE, text = "Disconnected (pending changes were written first)."); bump() })
    output$result <- renderUI({ m <- rv$msg; if (is.null(m)) return(NULL); callout(htmltools::htmlEscape(m$text), if (m$ok) "success" else "warn") })

    output$tables <- DT::renderDT({
      rv$tick; if (!is.null(bus)) bus$db_tick; invalidateLater(5000)
      pend <- table(factor(vapply(.bq$queue, function(i) i$table, ""), levels = names(BQ_SCHEMA)))
      d <- data.frame(Table = paste0(.bq$prefix, names(BQ_SCHEMA)),
                      `Full name` = sprintf("%s.%s.%s%s", .bq$project, .bq$dataset, .bq$prefix, names(BQ_SCHEMA)),
                      Rows = vapply(names(BQ_SCHEMA), function(t) nrow(.mem$tables[[t]] %||% bq_empty(t)), 1L),
                      Pending = as.integer(pend[names(BQ_SCHEMA)]),
                      Key = vapply(names(BQ_SCHEMA), function(t) paste(BQ_KEYS[[t]] %||% (if ("id" %in% names(BQ_SCHEMA[[t]])) "id" else ""), collapse = ", "), ""),
                      Holds = unname(BQ_DESCRIPTION[names(BQ_SCHEMA)]),
                      Columns = vapply(BQ_SCHEMA, length, 1L), check.names = FALSE, stringsAsFactors = FALSE)
      DT::datatable(d, rownames = FALSE, options = list(dom = "t", pageLength = 20))
    })
    observeEvent(input$test, {
      if (!bq_state()$ready) { rv$test <- data.frame(Message = "Connect first."); return() }
      t <- input$test_table; skip <- BQ_SKIP_ON_LOAD[[t]]
      sel <- if (length(skip)) sprintf("* EXCEPT(%s)", paste(bq_id(skip), collapse = ", ")) else "*"
      rv$test <- tryCatch(bq_get(sprintf("SELECT %s FROM %s LIMIT 5", sel, bq_full(t))),
                          error = function(e) data.frame(Error = conditionMessage(e)))
      if (!nrow(rv$test)) rv$test <- data.frame(Message = "The table exists and is empty.")
    })
    output$test_out <- DT::renderDT({ req(rv$test); DT::datatable(rv$test, rownames = FALSE, options = list(dom = "t", scrollX = TRUE)) })
    output$ddl <- renderUI({ rv$tick; tags$pre(style = "font-size:12px; max-height:420px; overflow:auto;", paste(vapply(names(BQ_SCHEMA), bq_ddl, ""), collapse = ";\n\n")) })
    output$log <- renderUI({
      rv$tick; invalidateLater(4000)
      tagList(
        if (length(.bq$dropped)) callout(sprintf("%d change(s) were rejected by BigQuery three times and set aside: %s", length(.bq$dropped),
                                                 htmltools::htmlEscape(.bq$dropped[[length(.bq$dropped)]]$error)), "warn"),
        tags$pre(style = "font-size:12px; max-height:300px; overflow:auto;", if (length(.bq$log)) paste(rev(.bq$log), collapse = "\n") else "(nothing yet)"))
    })
  })
}
