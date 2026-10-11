# modules/trading_evidence.R
# Order Evidence: (1) platform screenshot -> fields using the Claude API (vision), reviewed and
# confirmed by the user, then sent to the Trading Records forms; (2) platform statement (CSV)
# import into BigQuery with reconciliation against recorded trades; (3) evidence log.
#
# Claude only TRANSCRIBES visible values. It never writes set-up reasoning, reasons for exit,
# lessons or evaluations: those stay with the user. Helpers live in R/utils_trading_records.R.

trading_evidence_ui <- function(id) {
  ns <- NS(id)
  lab <- function(x) tags$span(style = "color:#2c3e50; font-weight:600; font-size:12.5px;", x)
  tags$div(
    tags$div(style = "background: linear-gradient(135deg, #002C3C 0%, #008A82 100%); border-radius: 12px; padding: 18px 22px; margin-bottom: 16px; color: #ffffff;",
      tags$h3(style = "margin: 0 0 6px 0; font-size: 19px; font-weight: 800; color: #ffffff;", "Order Evidence: screenshots and platform statements"),
      tags$div(style = "font-size: 13px; color: #eafffb; line-height: 1.6;",
        "Read the numbers from a platform screenshot with Claude, check them against the image, and send them to your trade forms. Import the platform's statement and reconcile it with what you recorded. Claude transcribes only; your set-up reasoning, reasons for exit and lessons are written by you.")),
    uiOutput(ns("statusBar")),
    tabBox(width = 12, id = ns("tabs"),

      tabPanel("1. Screenshot to fields",
        tags$div(style = "font-size:12px; color:#64748b; margin-bottom:10px; line-height:1.5;",
          "Use a screenshot of the deal ticket, confirmation or closed position. Crop out account numbers and personal details before uploading: the image is sent to the Anthropic API. PNG, JPEG, WebP or GIF, up to about 5 MB."),
        fluidRow(
          column(4, selectInput(ns("ex_kind"), lab("What is in the screenshot?"), tr_vision_kinds)),
          column(4, fileInput(ns("ex_file"), lab("Screenshot"), accept = c("image/png", "image/jpeg", "image/webp", "image/gif", ".png", ".jpg", ".jpeg", ".webp", ".gif"))),
          column(4, textInput(ns("ex_dropbox"), lab("Where the original is saved (Dropbox path)"), ""))),
        actionButton(ns("ex_read"), "Read with Claude", icon = icon("wand-magic-sparkles"), class = "btn-primary", style = "color:#ffffff; font-weight:700;"),
        tags$br(), tags$br(),
        fluidRow(
          column(5, uiOutput(ns("ex_preview"))),
          column(7,
            tags$div(style = "font-weight:800; color:#002C3C; margin-bottom:6px;", "Extracted values (edit anything that does not match the image)"),
            fluidRow(column(4, textInput(ns("f_asset"), lab("Instrument"), "")),
                     column(4, selectInput(ns("f_dir"), lab("Direction"), c("", Buy = "B", Sell = "S"))),
                     column(4, numericInput(ns("f_size"), lab("Size"), NA))),
            fluidRow(column(4, numericInput(ns("f_entry"), lab("Entry price"), NA)),
                     column(4, numericInput(ns("f_stop"), lab("Stop"), NA)),
                     column(4, numericInput(ns("f_limit"), lab("Limit / target"), NA))),
            fluidRow(column(4, numericInput(ns("f_exit"), lab("Exit price"), NA)),
                     column(4, numericInput(ns("f_pnl"), lab("Profit / loss"), NA)),
                     column(4, textInput(ns("f_ref"), lab("Deal reference"), ""))),
            fluidRow(column(4, suppressWarnings(dateInput(ns("f_date"), lab("Date"), value = as.Date(NA)))),
                     column(4, textInput(ns("f_time"), lab("Time (UK, HH:MM)"), "")),
                     column(4, textInput(ns("f_platform"), lab("Platform"), ""))),
            uiOutput(ns("ex_checks")), uiOutput(ns("ex_conf")))),
        textAreaInput(ns("ex_notes"), lab("Your note on this screenshot (optional)"), rows = 2, width = "100%"),
        actionButton(ns("ex_send_open"), "Send to Trades: open-trade form", icon = icon("arrow-right"), class = "btn-success", style = "color:#ffffff; font-weight:700;"),
        actionButton(ns("ex_send_close"), "Send to Trades: exit form", icon = icon("arrow-right"), class = "btn-success", style = "color:#ffffff; font-weight:700;"),
        actionButton(ns("ex_discard"), "Discard this extraction", icon = icon("trash")),
        tags$div(style = "font-size:12px; color:#64748b; margin-top:8px;", "Sending fills the form fields only. You still write the set-up, trigger, reasons for stop and target, reason for exit and lessons yourself, then save the trade.")),

      tabPanel("2. Platform statement (CSV)",
        tags$div(style = "font-size:12px; color:#64748b; margin-bottom:10px; line-height:1.5;",
          "Export your closed-trade or transaction history from the platform as CSV (if you only get Excel, save it as CSV). Match the columns once, import the rows to BigQuery, then reconcile them against the trades you recorded."),
        fluidRow(column(5, fileInput(ns("st_file"), lab("Statement CSV"), accept = c(".csv", "text/csv"))),
                 column(4, textInput(ns("st_platform"), lab("Platform name"), "")),
                 column(3, numericInput(ns("st_tol"), lab("Match window (minutes)"), 15, min = 1, max = 240))),
        uiOutput(ns("st_map")), tags$div(style = "font-weight:800; color:#002C3C; margin:8px 0;", "Preview of the rows as the app reads them"),
        tableOutput(ns("st_preview")),
        actionButton(ns("st_import"), "Import rows to BigQuery", icon = icon("cloud-arrow-up"), class = "btn-primary", style = "color:#ffffff; font-weight:700;"),
        actionButton(ns("st_reconcile"), "Reconcile with my trades", icon = icon("scale-balanced"), class = "btn-success", style = "color:#ffffff; font-weight:700;"),
        tags$hr(), uiOutput(ns("rc_summary")),
        tags$div(style = "font-weight:800; color:#002C3C; margin:8px 0;", "Statement rows"), tableOutput(ns("rc_fills")),
        tags$div(style = "font-weight:800; color:#002C3C; margin:8px 0;", "Your closed trades"), tableOutput(ns("rc_trades")),
        checkboxInput(ns("rc_ok"), lab("I have reviewed the differences and want the statement P/L recorded on the matched trades"), FALSE),
        actionButton(ns("rc_apply"), "Apply statement P/L to matched trades", icon = icon("check"))),

      tabPanel("3. Evidence log",
        tags$div(style = "font-size:12px; color:#64748b; margin-bottom:10px;", "Every screenshot read, with its status: EXTRACTED, CONFIRMED (sent to a form), LINKED (saved on a trade), FAILED or DISCARDED. Images stay in Dropbox; BigQuery holds the extracted values, the checks and a file fingerprint (MD5)."),
        downloadButton(ns("dl_log"), "Download log (CSV)"), tags$br(), tags$br(), DT::DTOutput(ns("log_table"))),

      tabPanel("4. How it works",
        tags$div(style = "color:#2c3e50; font-size:13.5px; line-height:1.7;",
          tags$ol(
            tags$li("You place and manage every order on the trading platform yourself. This app never places, changes or closes an order."),
            tags$li("A screenshot is sent to the Claude API with an instruction to copy the visible values and nothing else. Anything not clearly visible comes back empty."),
            tags$li("The values appear beside the image. You correct them, and automatic checks flag a stop on the wrong side of the entry, a missing stop, unreadable fields and low-confidence readings."),
            tags$li("Sending to Trades fills the form fields. The trade is marked SCREENSHOT_VERIFIED only when you save it."),
            tags$li("The platform statement is a second, independent source. Reconciliation shows rows you never recorded, trades that are not in the statement, and profit/loss differences."),
            tags$li("Everything is stored in BigQuery tables (evidence and platform fills) with the same append-only design as the rest of your records.")),
          tags$h4(style = "color:#002C3C; font-weight:800;", "Limits"),
          tags$ul(
            tags$li("Reading numbers from images can fail on small, blurred or cropped text. Always compare with the image."),
            tags$li("Size can mean lots, contracts or pounds per point depending on the platform; check before using it as your stake per pip."),
            tags$li("Times are read as UK time unless you correct them."),
            tags$li("The statement column matching is a guess from the header names; check the preview before importing."),
            tags$li("Check your course's rules on AI-assisted record keeping and describe the use honestly in your write-up."))))
    )
  )
}

trading_evidence_server <- function(id, api_manager = NULL, store, bus, vision_fn = NULL, quiet = FALSE) {
  moduleServer(id, function(input, output, session) {
    msg <- function(text, type = "message") if (!quiet) showNotification(text, type = type, duration = 7)
    if (is.null(vision_fn)) vision_fn <- function(images, prompt) api_manager$call_claude_vision(images, prompt)
    refresh <- reactiveVal(0); bump <- function() refresh(isolate(refresh()) + 1)
    rd <- function(name) reactive({ refresh(); tr_read_current(store, name) })
    evidence_df <- rd("evidence"); trades_df <- rd("trades"); levels_df <- rd("morning_levels")
    rv <- reactiveValues(img = NULL, ext = NULL, ev_id = NULL, kind = NULL, model = NA_character_, parsed = NULL, fills = NULL, rc = NULL)

    output$statusBar <- renderUI({
      invalidateLater(4000)
      cl <- isTRUE(tryCatch(api_manager$claude_authenticated, error = function(e) FALSE)); bq <- store$connected()
      pill <- function(ok, t) tags$span(style = paste0("display:inline-block; margin-right:8px; padding:3px 10px; border-radius:12px; font-size:12px; color:#ffffff; background:", if (ok) "#15803d" else "#b45309"), t)
      tags$div(style = "margin-bottom:10px;", pill(cl || !is.null(vision_fn) && is.null(api_manager), if (cl) "Claude API connected" else "Claude API not connected (API Configuration)"),
               pill(bq, if (bq) "BigQuery connected" else "BigQuery not connected: records are kept in this session only"))
    })

    # ---------------------------------------------------------------- screenshot -> fields
    log_evidence <- function(status, extra = list()) {
      prev <- tr_read_current(store, "evidence"); id <- rv$ev_id
      rvn <- if (!is.null(id) && id %in% prev$evidence_id) prev$record_version[prev$evidence_id == id][1] + 1L else 1L
      base <- list(evidence_id = id, record_version = rvn, kind = rv$kind, status = status, file_name = rv$img$name, file_md5 = rv$img$md5,
                   mime = rv$img$media_type, size_bytes = as.integer(rv$img$bytes), dropbox_path = tr_blank_na(input$ex_dropbox), model = rv$model,
                   extracted_json = if (is.null(rv$parsed)) NA_character_ else as.character(jsonlite::toJSON(rv$parsed, auto_unbox = TRUE, null = "null")),
                   user_notes = tr_blank_na(input$ex_notes))
      row <- as.data.frame(modifyList(base, extra), stringsAsFactors = FALSE)
      store$write("evidence", row); bump()
    }

    observeEvent(input$ex_read, {
      req(input$ex_file)
      img <- tryCatch(tr_read_image(input$ex_file$datapath, input$ex_file$name), error = function(e) { msg(conditionMessage(e), "error"); NULL })
      req(img)
      dup <- evidence_df(); dup <- dup[!is.na(dup$file_md5) & dup$file_md5 == img$md5, ]
      if (nrow(dup)) msg(sprintf("This exact image was already processed (%s, %s).", dup$evidence_id[1], dup$status[1]), "warning")
      rv$img <- img; rv$kind <- input$ex_kind; rv$ev_id <- tr_id("EV"); rv$ext <- NULL; rv$parsed <- NULL
      res <- tryCatch(withProgress(message = "Reading the screenshot with Claude...", value = 0.4,
                                   vision_fn(list(list(media_type = img$media_type, data = img$data)), tr_vision_prompt(input$ex_kind))),
                      error = function(e) { cat("[Evidence] Claude call failed:", conditionMessage(e), "\n"); msg(paste("Claude could not read the image:", conditionMessage(e)), "error"); NULL })
      if (is.null(res)) { log_evidence("FAILED", list(checks_json = "claude call failed")); return() }
      rv$model <- tr_or(res$model, NA_character_)
      parsed <- tr_parse_vision_json(res$text); rv$parsed <- parsed
      tok <- list(input_tokens = as.integer(tr_or(res$usage$input_tokens, NA)), output_tokens = as.integer(tr_or(res$usage$output_tokens, NA)))
      if (is.null(parsed)) {
        cat("[Evidence] Could not parse JSON from reply:", substr(res$text, 1, 200), "\n")
        msg("Claude's reply could not be read as values. Enter the details by hand, or try a clearer screenshot.", "error")
        log_evidence("FAILED", c(list(checks_json = "unparseable reply"), tok)); return()
      }
      e <- tr_normalise_extraction(parsed); rv$ext <- e
      updateTextInput(session, "f_asset", value = tr_or(e$asset, "")); updateSelectInput(session, "f_dir", selected = tr_or(e$direction, ""))
      for (p in list(c("f_size", "size"), c("f_entry", "entry"), c("f_stop", "stop"), c("f_limit", "limit"), c("f_exit", "exit"), c("f_pnl", "pnl")))
        updateNumericInput(session, p[1], value = if (is.finite(e[[p[2]]])) e[[p[2]]] else NA)
      updateTextInput(session, "f_ref", value = tr_or(e$deal_ref, "")); updateTextInput(session, "f_platform", value = tr_or(e$platform, ""))
      updateDateInput(session, "f_date", value = if (is.na(e$date)) NA else e$date); updateTextInput(session, "f_time", value = tr_or(e$time, ""))
      chk <- tr_check_extraction(e, input$ex_kind, levels_df())
      log_evidence("EXTRACTED", c(list(checks_json = as.character(jsonlite::toJSON(chk))), tok))
      msg("Read complete. Compare every value with the image before using it.")
    })

    output$ex_preview <- renderUI({
      im <- rv$img; if (is.null(im)) return(tags$div(style = "color:#64748b; font-size:12.5px;", "The screenshot appears here after you read it."))
      tags$img(src = paste0("data:", im$media_type, ";base64,", gsub("\\s", "", im$data)), style = "max-width:100%; border:1px solid #e2e8f0; border-radius:8px;")
    })

    cur_ext <- reactive({
      e <- rv$ext; if (is.null(e)) e <- list(confidence = character(0))
      list(asset = tr_norm_asset(tr_or(input$f_asset, NA)), direction = if (nzchar(tr_or(input$f_dir, ""))) input$f_dir else NA_character_,
           size = tr_num(input$f_size), entry = tr_num(input$f_entry), stop = tr_num(input$f_stop), limit = tr_num(input$f_limit), exit = tr_num(input$f_exit),
           pnl = tr_num(input$f_pnl), date = if (length(input$f_date) && !is.na(input$f_date)) as.Date(input$f_date) else as.Date(NA),
           time = if (nzchar(tr_or(input$f_time, ""))) input$f_time else NA_character_, deal_ref = tr_blank_na(input$f_ref), platform = tr_blank_na(input$f_platform),
           confidence = e$confidence)
    })
    checks <- reactive({ req(rv$img); tr_check_extraction(cur_ext(), tr_or(rv$kind, input$ex_kind), levels_df()) })
    output$ex_checks <- renderUI({
      if (is.null(rv$img) || is.null(rv$ext)) return(NULL)
      ck <- checks(); col <- c(error = "#b91c1c", warn = "#b45309", info = "#475569", ok = "#15803d")
      tags$div(style = "margin-top:8px;", lapply(seq_len(nrow(ck)), function(i) tags$div(style = paste0("font-size:12.5px; color:", col[[ck$level[i]]], "; margin-bottom:3px;"), paste0(toupper(ck$level[i]), ": ", ck$message[i]))))
    })
    output$ex_conf <- renderUI({
      cf <- rv$ext$confidence; if (!length(cf)) return(NULL)
      tags$div(style = "font-size:12px; color:#64748b; margin-top:6px;", paste("Claude's confidence:", paste(sprintf("%s %s", names(cf), cf), collapse = " · ")))
    })

    send <- function(kind) {
      if (is.null(rv$img) || is.null(rv$ext)) { msg("Read a screenshot first.", "warning"); return() }
      ck <- checks(); if (any(ck$level == "error")) { msg("Fix the errors listed under the values first (edit them to match the image).", "error"); return() }
      v <- cur_ext()
      conf <- as.character(jsonlite::toJSON(list(asset = v$asset, direction = v$direction, size = v$size, entry = v$entry, stop = v$stop, limit = v$limit,
                                                 exit = v$exit, pnl = v$pnl, date = as.character(v$date), time = v$time, deal_ref = v$deal_ref), auto_unbox = TRUE, na = "null"))
      log_evidence("CONFIRMED", list(confirmed_json = conf, checks_json = as.character(jsonlite::toJSON(ck))))
      bus$kind <- kind; bus$values <- v; bus$evidence_id <- rv$ev_id; bus$ts <- isolate(bus$ts) + 1
      tryCatch(shinydashboard::updateTabItems(session$rootScope(), "sidebar_menu", "trading_records"), error = function(e) NULL)
    }
    observeEvent(input$ex_send_open, send("open")); observeEvent(input$ex_send_close, send("close"))
    observeEvent(input$ex_discard, {
      if (is.null(rv$img)) return(); log_evidence("DISCARDED"); rv$img <- NULL; rv$ext <- NULL; rv$parsed <- NULL; msg("Extraction discarded.")
    })

    output$log_table <- DT::renderDT({
      e <- evidence_df()
      if (!nrow(e)) return(DT::datatable(data.frame(Message = "No screenshots processed yet."), rownames = FALSE, options = list(dom = "t")))
      e <- e[order(e$saved_at, decreasing = TRUE), ]
      DT::datatable(e[, c("evidence_id", "kind", "status", "trade_id", "file_name", "dropbox_path", "model", "input_tokens", "output_tokens", "record_version")], rownames = FALSE, options = list(pageLength = 10, scrollX = TRUE))
    })
    output$dl_log <- downloadHandler(filename = function() paste0("trading_evidence_", format(Sys.Date()), ".csv"),
                                     content = function(file) write.csv(evidence_df(), file, row.names = FALSE, na = ""))

    # ---------------------------------------------------------------- statement import + reconcile
    st_raw <- reactive({ req(input$st_file); tryCatch(tr_stmt_read(input$st_file$datapath), error = function(e) { msg(conditionMessage(e), "error"); NULL }) })
    output$st_map <- renderUI({
      d <- st_raw(); req(d); g <- tr_stmt_guess_map(names(d))
      tags$div(style = "background:#f6f8fb; border-radius:8px; padding:8px 12px; margin-bottom:8px;",
        tags$div(style = "font-weight:800; color:#002C3C; margin-bottom:4px;", "Match the columns (guessed from the headers)"),
        fluidRow(lapply(names(tr_stmt_fields), function(f) column(3, selectInput(session$ns(paste0("mp_", f)),
          tags$span(style = "color:#2c3e50; font-weight:600; font-size:12.5px;", tr_stmt_fields[[f]]), c("(none)", names(d)), selected = tr_or(g[[f]], "(none)"))))))
    })
    st_map_now <- reactive({ d <- st_raw(); req(d); g <- tr_stmt_guess_map(names(d))
      m <- vapply(names(tr_stmt_fields), function(f) { v <- input[[paste0("mp_", f)]]; if (is.null(v)) tr_or(g[[f]], NA_character_) else if (identical(v, "(none)")) NA_character_ else v }, ""); m })
    fills_norm <- reactive({ d <- st_raw(); req(d); tr_stmt_normalise(d, st_map_now(), input$st_file$name, tr_blank_na(input$st_platform)) })
    output$st_preview <- renderTable({
      f <- fills_norm(); f$open_ts <- format(f$open_ts, "%d/%m/%Y %H:%M", tz = "Europe/London"); f$close_ts <- format(f$close_ts, "%d/%m/%Y %H:%M", tz = "Europe/London")
      head(f[, c("deal_ref", "close_ts", "asset", "direction", "size", "open_price", "close_price", "pnl_gbp")], 8)
    }, striped = TRUE, bordered = TRUE, spacing = "s", na = "")
    observeEvent(input$st_import, {
      f <- fills_norm(); ok <- !is.na(f$close_ts) & !is.na(f$asset); skipped <- sum(!ok)
      if (!any(ok)) { msg("No usable rows: check the close date/time and instrument columns.", "error"); return() }
      res <- store$write("platform_fills", f[ok, ])
      msg(sprintf("%d row(s) imported (%s)%s.", sum(ok), res, if (skipped) sprintf("; %d skipped for a missing date or instrument", skipped) else ""), if (identical(res, "bigquery")) "message" else "warning")
      rv$fills <- f[ok, ]
    })
    observeEvent(input$st_reconcile, {
      f <- tryCatch(fills_norm(), error = function(e) NULL); req(f)
      f <- f[!is.na(f$close_ts) & !is.na(f$asset), ]; rv$fills <- f; bump()
      rv$rc <- tr_reconcile(f, trades_df(), input$st_tol)
    })
    output$rc_summary <- renderUI({
      r <- rv$rc; if (is.null(r)) return(tags$div(style = "color:#64748b; font-size:12.5px;", "Run the reconciliation to compare the statement with your recorded trades."))
      tb <- table(factor(r$fills$status, levels = c("MATCHED", "PNL_DIFFERS", "MATCHED_NO_PNL", "UNRECORDED")))
      nt <- sum(r$trades$status == "NOT_IN_STATEMENT")
      tags$div(style = "font-size:13px; color:#2c3e50; line-height:1.7;",
        sprintf("Statement rows: %d matched, %d with a P/L difference, %d matched without a P/L figure, %d not recorded by you. Your closed trades missing from the statement: %d.",
                tb[["MATCHED"]], tb[["PNL_DIFFERS"]], tb[["MATCHED_NO_PNL"]], tb[["UNRECORDED"]], nt))
    })
    output$rc_fills <- renderTable({ r <- rv$rc; req(r); f <- r$fills; f$close_ts <- format(f$close_ts, "%d/%m %H:%M", tz = "Europe/London")
      f[, c("close_ts", "asset", "direction", "size", "close_price", "pnl_gbp", "status", "matched_trade_id", "pnl_diff")] }, striped = TRUE, bordered = TRUE, spacing = "s", na = "")
    output$rc_trades <- renderTable({ r <- rv$rc; req(r); t <- r$trades; t$exit_ts <- format(t$exit_ts, "%d/%m %H:%M", tz = "Europe/London")
      t[, c("trade_sheet_name", "asset", "direction", "exit_ts", "net_pnl_gbp", "pnl_source", "status")] }, striped = TRUE, bordered = TRUE, spacing = "s", na = "")
    observeEvent(input$rc_apply, {
      r <- rv$rc; req(r)
      if (!isTRUE(input$rc_ok)) { msg("Tick the review box first.", "warning"); return() }
      f <- r$fills[r$fills$status %in% c("PNL_DIFFERS", "MATCHED_NO_PNL") & is.finite(r$fills$pnl_gbp), , drop = FALSE]
      if (!nrow(f)) { msg("Nothing to apply: no matched trades with a different statement P/L.", "warning"); return() }
      t <- trades_df(); n <- 0L
      for (i in seq_len(nrow(f))) {
        tr <- t[t$trade_id == f$matched_trade_id[i], , drop = FALSE]; if (nrow(tr) != 1) next
        tr$record_version <- tr$record_version + 1L; tr$net_pnl_gbp <- f$pnl_gbp[i]; tr$pnl_source <- "STATEMENT"; tr$statement_fill_id <- f$fill_id[i]
        tr$real_r <- if (is.finite(tr$initial_risk_gbp) && tr$initial_risk_gbp > 0) f$pnl_gbp[i] / tr$initial_risk_gbp else NA_real_
        store$write("trades", tr); n <- n + 1L
      }
      bump(); rv$rc <- NULL; msg(sprintf("Statement P/L recorded on %d trade(s). Run the reconciliation again to confirm.", n))
    })
  })
}
