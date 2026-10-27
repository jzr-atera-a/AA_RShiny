# modules/trading_evidence.R
# Order Evidence: (1) platform screenshot -> fields using the Claude API (vision), reviewed and
# confirmed by the user, then sent to the Trading Records forms; (2) an evidence log.
#
# Claude only TRANSCRIBES visible values. It never writes set-up reasoning, reasons for exit,
# lessons or evaluations: those stay with the user. Helpers live in R/utils_trading_records.R.

trading_evidence_ui <- function(id) {
  ns <- NS(id)
  lab <- function(x) tags$span(style = "color:#2c3e50; font-weight:600; font-size:12.5px;", x)
  tags$div(
    tags$div(style = "background: linear-gradient(135deg, #002C3C 0%, #008A82 100%); border-radius: 12px; padding: 18px 22px; margin-bottom: 16px; color: #ffffff;",
      tags$h3(style = "margin: 0 0 6px 0; font-size: 19px; font-weight: 800; color: #ffffff;", "Order Evidence: reading platform screenshots"),
      tags$div(style = "font-size: 13px; color: #eafffb; line-height: 1.6;",
        "Read the numbers from a platform screenshot with Claude, check them against the image, and send them to your trade forms. Claude transcribes only; your set-up reasoning, reasons for exit and lessons are written by you.")),
    uiOutput(ns("statusBar")),
    tabBox(width = 12, id = ns("tabs"),

      tabPanel("1. Screenshot to fields",
        tags$style(HTML("
          .ev-source .shiny-options-group { display:flex; gap:0; }
          .ev-source label.radio-inline { margin:0 !important; padding:7px 18px !important; border:2px solid #008A82; background:#ffffff; color:#006b65; font-weight:700; font-size:13px; cursor:pointer; position:relative; }
          .ev-source label.radio-inline:first-child { border-radius:20px 0 0 20px; }
          .ev-source label.radio-inline:last-child { border-radius:0 20px 20px 0; border-left:0; }
          .ev-source label.radio-inline input[type=radio] { position:absolute; opacity:0; width:0; height:0; margin:0; }
          .ev-source label.radio-inline:has(input:checked) { background:#008A82 !important; color:#ffffff !important; }
          .ev-source label.radio-inline:has(input:checked) span { color:#ffffff !important; }")),
        tags$div(style = "font-size:12px; color:#64748b; margin-bottom:10px; line-height:1.5;",
          "Select one or several screenshots at once (for example the ticket, the open position and the closed trade of one trade). Claude works out what each screen is. Crop out account numbers and personal details before uploading: the images are sent to the Anthropic API. PNG, JPEG, WebP or GIF, up to about 5 MB each. Upload screenshots from one source (mobile or desktop) at a time."),
        fluidRow(
          column(4, tags$div(class = "ev-source",
            tags$div(style = "color:#2c3e50; font-weight:600; font-size:12.5px; margin-bottom:4px;", "Screenshot source (switch)"),
            radioButtons(ns("ex_source"), NULL, tr_vision_sources, selected = "mobile", inline = TRUE))),
          column(8, uiOutput(ns("ex_source_hint")))),
        fluidRow(
          column(7, fileInput(ns("ex_file"), lab("Screenshots (select one or several)"), multiple = TRUE, accept = c("image/png", "image/jpeg", "image/webp", "image/gif", ".png", ".jpg", ".jpeg", ".webp", ".gif"))),
          column(5, selectInput(ns("ex_kind"), lab("Screen type (leave on Auto-detect: Claude decides)"), tr_vision_kinds))),
        actionButton(ns("ex_read"), "Read all with Claude", icon = icon("wand-magic-sparkles"), class = "btn-primary", style = "color:#ffffff; font-weight:700;"),
        tags$br(), tags$br(),
        uiOutput(ns("ex_items")),
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
                     column(4, numericInput(ns("f_pnl"), lab("Profit / loss (closed trade)"), NA)),
                     column(4, textInput(ns("f_ref"), lab("Deal reference"), ""))),
            fluidRow(column(4, numericInput(ns("f_cur"), lab("Current price (open position)"), NA)),
                     column(4, numericInput(ns("f_upnl"), lab("Unrealised profit / loss (open position)"), NA)),
                     column(4, tags$div(style = "font-size:11.5px; color:#64748b; padding-top:24px; line-height:1.4;", "Open-position figures are kept as evidence only; the trade's result comes from the closed-trade screen."))),
            fluidRow(column(4, suppressWarnings(dateInput(ns("f_date"), lab("Date"), value = as.Date(NA)))),
                     column(4, textInput(ns("f_time"), lab("Time (UK, HH:MM)"), "")),
                     column(4, textInput(ns("f_platform"), lab("Platform"), ""))),
            uiOutput(ns("ex_extra")), uiOutput(ns("ex_checks")), uiOutput(ns("ex_conf")))),
        textAreaInput(ns("ex_notes"), lab("Your note on this screenshot (optional)"), rows = 2, width = "100%"),
        actionButton(ns("ex_send_auto"), "Send to Trades (right form for this screen)", icon = icon("arrow-right"), class = "btn-success", style = "color:#ffffff; font-weight:700;"),
        actionButton(ns("ex_send_open"), "Send to Trades: open-trade form", icon = icon("arrow-right"), class = "btn-success", style = "color:#ffffff; font-weight:700;"),
        actionButton(ns("ex_send_close"), "Send to Trades: exit form", icon = icon("arrow-right"), class = "btn-success", style = "color:#ffffff; font-weight:700;"),
        actionButton(ns("ex_save_only"), "Save as evidence only (no form)", icon = icon("floppy-disk"), class = "btn-primary", style = "color:#ffffff; font-weight:700;"),
        actionButton(ns("ex_discard"), "Discard this extraction", icon = icon("trash")),
        tags$div(style = "font-size:12px; color:#64748b; margin-top:8px;", "Pick each screenshot from the list above to review it. The file name of each screenshot is saved in the evidence log, so you can find the original in your own Screenshots folder; the app does not store the image. Sending fills the form fields only. You still write the set-up, trigger, reasons for stop and target, reason for exit and lessons yourself, then save the trade. Ticket and market screens are record-only: save them as evidence.")),

      tabPanel("2. Evidence log",
        tags$div(style = "font-size:12px; color:#64748b; margin-bottom:10px;", "Every screenshot read, with its status: EXTRACTED, CONFIRMED (sent to a form), LINKED (saved on a trade), FAILED or DISCARDED. The image itself is not stored (it stays in your Screenshots folder); BigQuery holds the extracted values, the checks and a file fingerprint (MD5)."),
        downloadButton(ns("dl_log"), "Download log (CSV)"), tags$br(), tags$br(), DT::DTOutput(ns("log_table"))),

      tabPanel("3. How it works",
        tags$div(style = "color:#2c3e50; font-size:13.5px; line-height:1.7;",
          tags$ol(
            tags$li("You place and manage every order on the trading platform yourself. This app never places, changes or closes an order."),
            tags$li("Choose the screenshot source first (Mobile app or Desktop website): the two layouts differ, so Claude gets a different description of what to look for. Select as many screenshots as you like in one go. Leave the screen type on Auto-detect: Claude decides whether each one is a ticket, an open position, a closed trade or a market screen. You can still force a type from the list."),
            tags$li("A screenshot is sent to the Claude API with an instruction to copy the visible values and nothing else. Anything not clearly visible comes back empty."),
            tags$li("The values appear beside the image. You correct them, and automatic checks flag a stop on the wrong side of the entry, a missing stop, unreadable fields and low-confidence readings."),
            tags$li("Sending to Trades fills the form fields. The trade is marked SCREENSHOT_VERIFIED only when you save it."),
            tags$li("Everything is stored in the BigQuery evidence table with the same append-only design as the rest of your records.")),
          tags$h4(style = "color:#002C3C; font-weight:800;", "Limits"),
          tags$ul(
            tags$li("Reading numbers from images can fail on small, blurred or cropped text. Always compare with the image."),
            tags$li("Size can mean lots, contracts or pounds per point depending on the platform; check before using it as your stake per pip."),
            tags$li("Times are read as UK time unless you correct them. The mobile Closed list shows dates only, and the chart axis times are not trade times, so enter the time of day yourself."),
            tags$li("A signed size such as +3 or -3 is turned into buy or sell by a fixed rule (+ buy, - sell) and is flagged as derived. A ticket shows stop and limit as distances in points; the levels come from the open-position screen."),
            tags$li("Each reading is matched to an asset class, market and asset (for example Commodity, Energy, Brent), and to a contract type (daily funded bet 'Undated' or Futures) and account type (spread bet or CFD). These are saved with the trade and with the evidence row so the Blotter and Trade Sheet use the same labels."),
            tags$li("IG shows risk:reward (risk divided by reward, for example 1.5:1). LAT's RRR is reward divided by risk (0.67 for the same trade). The app calculates the LAT figure itself and never saves the platform's ratio."),
            tags$li("A ticket can be sent to the open-trade form for its size, margin, notional, costs and contract type, but not its levels: those are indicative quotes."),
            tags$li("Check your course's rules on AI-assisted record keeping and describe the use honestly in your write-up."))))
    )
  )
}

trading_evidence_server <- function(id, api_manager = NULL, store, bus, vision_fn = NULL, quiet = FALSE, pictures = NULL) {
  moduleServer(id, function(input, output, session) {
    msg <- function(text, type = "message") if (!quiet) showNotification(text, type = type, duration = 7)
    if (is.null(vision_fn)) vision_fn <- function(images, prompt) api_manager$call_claude_vision(images, prompt)
    refresh <- reactiveVal(0); bump <- function() refresh(isolate(refresh()) + 1)
    rd <- function(name) reactive({ refresh(); tr_read_current(store, name) })
    evidence_df <- rd("evidence"); trades_df <- rd("trades"); levels_df <- rd("morning_levels")
    rv <- reactiveValues(img = NULL, ext = NULL, ev_id = NULL, kind = NULL, source = NULL, model = NA_character_, parsed = NULL, items = list(), cur = NULL, path = NA_character_)
    # where screenshots are kept (Dropbox folder / API, set in Trading Records > Setup); a session-only store until then
    pic_store <- function() { s <- if (!is.null(pictures)) pictures$store else NULL; if (is.null(s)) { if (is.null(rv$fallback)) rv$fallback <- tr_image_store(); s <- rv$fallback }; s }

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
                   mime = rv$img$media_type, size_bytes = as.integer(rv$img$bytes), model = rv$model, dropbox_path = tr_or(rv$path, NA_character_),
                   extracted_json = if (is.null(rv$parsed)) NA_character_ else as.character(jsonlite::toJSON(rv$parsed, auto_unbox = TRUE, null = "null")),
                   user_notes = tr_blank_na(input$ex_notes),
                   source_device = tr_blank_na(rv$source), screen_type = tr_blank_na(rv$parsed$screen_type),
                   asset_code = tr_blank_na(rv$ext$asset), asset_class = tr_blank_na(rv$ext$asset_class), market = tr_blank_na(rv$ext$market),
                   contract_type = tr_blank_na(rv$ext$contract))
      if (!is.null(id) && id %in% prev$evidence_id) {   # later versions keep the token counts of the reading
        pr <- prev[prev$evidence_id == id, , drop = FALSE]; pr <- pr[which.max(pr$record_version), ]
        if (is.null(extra$input_tokens)) base$input_tokens <- pr$input_tokens
        if (is.null(extra$output_tokens)) base$output_tokens <- pr$output_tokens
      }
      row <- as.data.frame(modifyList(base, extra), stringsAsFactors = FALSE)
      store$write("evidence", row); bump()
    }

    src_now <- reactive(tr_or(input$ex_source, "mobile"))
    output$ex_source_hint <- renderUI({
      st <- "font-size:12px; color:#334155; background:#f1f5f9; border-radius:8px; padding:8px 12px; line-height:1.55; margin-top:2px;"
      if (identical(src_now(), "desktop"))
        tags$div(style = st, tags$b("Desktop website. "), "Capture the deal ticket (size, stop, limit), the Positions and Orders tables, and History. If a table shows several rows, select the one you want or crop to it so Claude reads the right row.")
      else
        tags$div(style = st, tags$b("Mobile app. "), "One trade usually needs four screens: the ", tags$b("New trade"), " ticket before you place it, ", tags$b("Position Detail"), " right after the fill (entry, stop and limit levels), ", tags$b("Market Detail"), " for the quote snapshot, and ", tags$b("Trades > Closed"), " after the exit. The Closed list shows dates but no time of day.")
    })
    kind_label <- c(open = "open position", ticket = "order ticket", close = "closed trade", market = "market screen", history = "history / statement")

    # ---- helpers for the list of screenshots read in one go
    fill_form <- function(e) {
      updateTextInput(session, "f_asset", value = tr_or(e$asset, "")); updateSelectInput(session, "f_dir", selected = tr_or(e$direction, ""))
      for (p in list(c("f_size", "size"), c("f_entry", "entry"), c("f_stop", "stop"), c("f_limit", "limit"), c("f_exit", "exit"), c("f_pnl", "pnl"), c("f_cur", "current"), c("f_upnl", "unrealised")))
        updateNumericInput(session, p[1], value = if (is.finite(tr_or(e[[p[2]]], NA_real_))) e[[p[2]]] else NA)
      updateTextInput(session, "f_ref", value = tr_or(e$deal_ref, "")); updateTextInput(session, "f_platform", value = tr_or(e$platform, ""))
      suppressWarnings(updateDateInput(session, "f_date", value = if (is.na(e$date)) NA else e$date)); updateTextInput(session, "f_time", value = tr_or(e$time, ""))
    }
    snap <- function() list(asset = input$f_asset, dir = input$f_dir, size = input$f_size, entry = input$f_entry, stop = input$f_stop, limit = input$f_limit,
                            exit = input$f_exit, pnl = input$f_pnl, cur = input$f_cur, upnl = input$f_upnl, ref = input$f_ref, platform = input$f_platform, date = input$f_date, time = input$f_time)
    restore <- function(f) {
      updateTextInput(session, "f_asset", value = tr_or(f$asset, "")); updateSelectInput(session, "f_dir", selected = tr_or(f$dir, ""))
      for (p in list(c("f_size", "size"), c("f_entry", "entry"), c("f_stop", "stop"), c("f_limit", "limit"), c("f_exit", "exit"), c("f_pnl", "pnl"), c("f_cur", "cur"), c("f_upnl", "upnl")))
        updateNumericInput(session, p[1], value = tr_or(f[[p[2]]], NA))
      updateTextInput(session, "f_ref", value = tr_or(f$ref, "")); updateTextInput(session, "f_platform", value = tr_or(f$platform, ""))
      suppressWarnings(updateDateInput(session, "f_date", value = if (length(f$date) && !is.na(f$date)) f$date else NA)); updateTextInput(session, "f_time", value = tr_or(f$time, ""))
    }
    set_mirror <- function(it) { rv$img <- it$img; rv$kind <- it$kind; rv$source <- it$source; rv$ev_id <- it$ev_id; rv$ext <- it$ext; rv$parsed <- it$parsed; rv$model <- tr_or(it$model, NA_character_); rv$path <- tr_or(it$path, NA_character_) }
    load_item <- function(i) {
      it <- rv$items[[i]]; set_mirror(it); rv$cur <- i
      if (!is.null(it$form)) restore(it$form) else if (!is.null(it$ext)) fill_form(it$ext)
    }
    mark <- function(status) { i <- rv$cur; if (!is.null(i) && i <= length(rv$items)) { its <- rv$items; its[[i]]$status <- status; rv$items <- its } }
    observeEvent(input$ex_pick, {
      i <- suppressWarnings(as.integer(input$ex_pick)); if (is.na(i) || is.null(rv$cur) || i == rv$cur || i > length(rv$items)) return()
      its <- rv$items; its[[rv$cur]]$form <- snap(); rv$items <- its; load_item(i)
    })
    output$ex_items <- renderUI({
      its <- rv$items; if (length(its) < 2) return(NULL)
      labs <- vapply(seq_along(its), function(i) { it <- its[[i]]
        what <- if (identical(it$status, "FAILED")) "could not be read" else kind_label[[tr_or(it$kind, "history")]]
        a <- if (!is.null(it$ext) && !is.na(tr_or(it$ext$asset, NA))) paste0(", ", it$ext$asset) else ""
        sprintf("%d. %s: %s%s [%s]", i, it$img$name, what, a, tolower(tr_or(it$status, "read"))) }, "")
      tags$div(style = "background:#f6f8fb; border-radius:8px; padding:8px 12px; margin-bottom:10px; color:#2c3e50;",
        radioButtons(session$ns("ex_pick"), tags$span(style = "font-weight:800; color:#002C3C;", sprintf("%d screenshots read: pick one to review", length(its))),
                     choices = setNames(seq_along(its), labs), selected = rv$cur))
    })

    observeEvent(input$ex_read, {
      files <- input$ex_file; req(files); n <- nrow(files)
      kind_in <- tr_or(input$ex_kind, "auto"); src <- src_now(); items <- list(); okn <- 0L
      withProgress(message = "Reading the screenshots with Claude...", value = 0, {
        for (i in seq_len(n)) {
          incProgress(1 / n, detail = files$name[i])
          img <- tryCatch(tr_read_image(files$datapath[i], files$name[i]), error = function(e) { msg(paste0(files$name[i], ": ", conditionMessage(e)), "error"); NULL })
          if (is.null(img)) next
          dup <- evidence_df(); dup <- dup[!is.na(dup$file_md5) & dup$file_md5 == img$md5, ]
          if (nrow(dup)) msg(sprintf("%s was already processed (%s, %s).", img$name, dup$evidence_id[1], dup$status[1]), "warning")
          it <- list(img = img, kind = kind_in, source = src, ev_id = tr_id("EV"), ext = NULL, parsed = NULL, model = NA_character_, status = "read", path = NA_character_)
          # keep the screenshot itself (Dropbox), so it can be placed on the Trade Sheet later without uploading it again
          it$path <- tryCatch(pic_store()$put(files$datapath[i], tr_picture_rel(it$ev_id, img$name, tr_london_today()))$path, error = function(e) { cat("[Evidence] picture not stored:", conditionMessage(e), "\n"); NA_character_ })
          set_mirror(it)
          res <- tryCatch(vision_fn(list(list(media_type = img$media_type, data = img$data)), tr_vision_prompt(kind_in, src)),
                          error = function(e) { cat("[Evidence] Claude call failed:", conditionMessage(e), "\n"); msg(paste0(img$name, ": Claude could not read the image: ", conditionMessage(e)), "error"); NULL })
          if (is.null(res)) { log_evidence("FAILED", list(checks_json = "claude call failed")); it$status <- "FAILED"; items[[length(items) + 1]] <- it; next }
          it$model <- tr_or(res$model, NA_character_); rv$model <- it$model
          parsed <- tr_parse_vision_json(res$text); rv$parsed <- parsed
          tok <- list(input_tokens = as.integer(tr_or(res$usage$input_tokens, NA)), output_tokens = as.integer(tr_or(res$usage$output_tokens, NA)))
          if (is.null(parsed)) {
            cat("[Evidence] Could not parse JSON from reply:", substr(res$text, 1, 200), "\n")
            msg(paste0(img$name, ": Claude's reply could not be read as values. Enter the details by hand, or try a clearer screenshot."), "error")
            log_evidence("FAILED", c(list(checks_json = "unparseable reply"), tok)); it$status <- "FAILED"; items[[length(items) + 1]] <- it; next
          }
          kind <- if (identical(kind_in, "auto")) tr_screen_to_kind(parsed$screen_type, parsed$activity_text) else kind_in
          parsed[["source_device"]] <- src; parsed[["resolved_kind"]] <- kind
          e <- tr_normalise_extraction(parsed, kind)
          if (is.na(e$date)) { e$date <- tr_london_today(); e$date_assumed <- TRUE }   # no date on the screen: today in London
          it$kind <- kind; it$parsed <- parsed; it$ext <- e; set_mirror(it)
          chk <- tr_check_extraction(e, kind, levels_df())
          log_evidence("EXTRACTED", c(list(checks_json = as.character(jsonlite::toJSON(chk))), tok))
          items[[length(items) + 1]] <- it; okn <- okn + 1L
        }
      })
      if (!length(items)) return()
      rv$items <- items; first <- which(vapply(items, function(z) !identical(z$status, "FAILED"), TRUE))[1]; if (is.na(first)) first <- 1L
      load_item(first)
      msg(sprintf("%d of %d screenshot(s) read (%s). Compare every value with the image before using it.", okn, n, if (identical(src, "desktop")) "desktop website" else "mobile app"))
    })

    output$ex_preview <- renderUI({
      im <- rv$img; if (is.null(im)) return(tags$div(style = "color:#64748b; font-size:12.5px;", "The screenshot appears here after you read it."))
      tags$img(src = paste0("data:", im$media_type, ";base64,", gsub("\\s", "", im$data)), style = "max-width:100%; border:1px solid #e2e8f0; border-radius:8px;")
    })

    cur_ext <- reactive({
      e <- rv$ext; if (is.null(e)) e <- list(confidence = character(0))
      list(asset = tr_norm_asset(tr_or(input$f_asset, NA)), direction = if (nzchar(tr_or(input$f_dir, ""))) input$f_dir else NA_character_,
           size = tr_num(input$f_size), entry = tr_num(input$f_entry), stop = tr_num(input$f_stop), limit = tr_num(input$f_limit), exit = tr_num(input$f_exit),
           pnl = tr_num(input$f_pnl), date = if (length(input$f_date) && !is.na(input$f_date) && nzchar(as.character(input$f_date))) tryCatch(as.Date(input$f_date), error = function(e) as.Date(NA)) else as.Date(NA),
           time = if (nzchar(tr_or(input$f_time, ""))) input$f_time else NA_character_, deal_ref = tr_blank_na(input$f_ref), platform = tr_blank_na(input$f_platform),
           date_assumed = isTRUE(e$date_assumed) && length(input$f_date) && isTRUE(tryCatch(as.Date(input$f_date) == e$date, error = function(err) FALSE)),
           per_point = isTRUE(e$per_point), demo = tr_or(e$demo, NA), derived = e$derived,
           asset_class = tr_or(e$asset_class, NA_character_), market = tr_or(e$market, NA_character_), contract = tr_or(e$contract, NA_character_),
           account_type = tr_or(e$account_type, NA_character_), source = tr_or(rv$source, NA_character_), size_unit = tr_or(e$size_unit, NA_character_),
           asset_raw = tr_or(e$asset_raw, NA_character_), margin = tr_or(e$margin, NA_real_), notional = tr_or(e$notional, NA_real_), costs = tr_or(e$costs, NA_real_),
           spread = tr_or(e$spread, NA_real_), rr_text = tr_or(e$rr_text, NA_character_), risk_amount = tr_or(e$risk_amount, NA_real_), reward_amount = tr_or(e$reward_amount, NA_real_),
           stop_dist = tr_or(e$stop_dist, NA_real_), limit_dist = tr_or(e$limit_dist, NA_real_), sell = tr_or(e$sell, NA_real_), buy = tr_or(e$buy, NA_real_),
           current = tr_num(input$f_cur), unrealised = tr_num(input$f_upnl), quote_time = tr_or(e$quote_time, NA_character_),
           confidence = e$confidence)
    })
    checks <- reactive({ req(rv$img); tr_check_extraction(cur_ext(), tr_or(rv$kind, input$ex_kind), levels_df()) })
    output$ex_extra <- renderUI({
      e <- rv$ext; if (is.null(rv$img) || is.null(e)) return(NULL)
      nz <- function(v) !(is.null(v) || length(v) == 0 || is.na(v))
      rows <- list(c("Screen", if (nzchar(tr_or(rv$kind, ""))) kind_label[[rv$kind]] else NA), c("Source", if (identical(rv$source, "desktop")) "Desktop website" else "Mobile app"),
                   c("Account badge", e$account_mode), c("Account type", e$account_type), c("Size unit", e$size_unit),
                   c("Asset class / market", if (!is.na(e$asset_class)) paste(e$asset_class, "/", e$market) else NA),
                   c("Contract", if (!is.na(e$contract)) c(DFB = "Daily funded bet (Undated)", FUTURES = "Futures (dated)")[[e$contract]] else NA),
                   c("Margin (GBP)", if (is.finite(e$margin)) format(e$margin) else NA), c("Notional (GBP)", if (is.finite(e$notional)) format(e$notional) else NA),
                   c("Indicative costs (GBP)", if (is.finite(e$costs)) format(e$costs) else NA), c("Spread (points)", if (is.finite(e$spread)) format(round(e$spread, 2)) else NA),
                   c("Platform risk:reward label", e$rr_text),
                   c("Stop distance (points)", if (nz(e$stop_dist) && is.finite(e$stop_dist)) format(e$stop_dist) else NA),
                   c("Limit distance (points)", if (nz(e$limit_dist) && is.finite(e$limit_dist)) format(e$limit_dist) else NA),
                   c("Sell quote", if (is.finite(e$sell)) format(e$sell) else NA), c("Buy quote", if (is.finite(e$buy)) format(e$buy) else NA),
                   c("Current price", if (is.finite(e$current)) format(e$current) else NA), c("Unrealised profit/loss", if (is.finite(e$unrealised)) format(e$unrealised) else NA),
                   c("Quote clock (Updated)", e$quote_time),
                   c("Opening date", if (!is.na(e$open_date)) format(e$open_date, "%d/%m/%Y") else NA), c("Closing date", if (!is.na(e$close_date)) format(e$close_date, "%d/%m/%Y") else NA))
      rows <- Filter(function(r) !is.na(r[2]), rows)
      if (!length(rows)) return(NULL)
      tags$div(style = "background:#f6f8fb; border-radius:8px; padding:8px 12px; margin-top:6px; font-size:12.5px; color:#2c3e50; line-height:1.6;",
        tags$div(style = "font-weight:800; color:#002C3C; margin-bottom:2px;", "Also read from the screen (platform details go to the open-trade form; the rest is kept as evidence)"),
        lapply(rows, function(r) tags$div(tags$span(style = "color:#64748b;", paste0(r[1], ": ")), r[2])))
    })
    output$ex_checks <- renderUI({
      if (is.null(rv$img) || is.null(rv$ext)) return(NULL)
      ck <- checks(); col <- c(error = "#b91c1c", warn = "#b45309", info = "#475569", ok = "#15803d")
      tags$div(style = "margin-top:8px;", lapply(seq_len(nrow(ck)), function(i) tags$div(style = paste0("font-size:12.5px; color:", col[[ck$level[i]]], "; margin-bottom:3px;"), paste0(toupper(ck$level[i]), ": ", ck$message[i]))))
    })
    output$ex_conf <- renderUI({
      cf <- rv$ext$confidence; if (!length(cf)) return(NULL)
      tags$div(style = "font-size:12px; color:#64748b; margin-top:6px;", paste("Claude's confidence:", paste(sprintf("%s %s", names(cf), cf), collapse = " · ")))
    })

    conf_json <- function(v, ck) as.character(jsonlite::toJSON(list(asset = v$asset, direction = v$direction, size = v$size, entry = v$entry, stop = v$stop, limit = v$limit,
                                               exit = v$exit, pnl = v$pnl, date = as.character(v$date), time = v$time, deal_ref = v$deal_ref,
                                               screen = rv$kind, source = rv$source, stop_distance = v$stop_dist, limit_distance = v$limit_dist, sell = v$sell, buy = v$buy,
                                               current = v$current, unrealised_pnl = v$unrealised, quote_time = v$quote_time,
                                               asset_class = v$asset_class, market = v$market, contract = v$contract, account_type = v$account_type,
                                               margin = v$margin, notional = v$notional, costs = v$costs, spread = v$spread, platform_rr_label = v$rr_text), auto_unbox = TRUE, na = "null"))
    send <- function(kind) {
      if (is.null(rv$img) || is.null(rv$ext)) { msg("Read a screenshot first.", "warning"); return() }
      k0 <- tr_or(rv$kind, "")
      if (identical(k0, "market") || (identical(k0, "ticket") && !identical(kind, "open"))) { msg("A market quote is a record only, and a ticket can only go to the open-trade form. Use 'Save as evidence only', or read the open-position / closed-trade screen.", "warning"); return() }
      ck <- checks(); if (any(ck$level == "error")) { msg("Fix the errors listed under the values first (edit them to match the image).", "error"); return() }
      v <- cur_ext()
      if (identical(k0, "ticket")) {   # a ticket's levels are indicative quotes: send size and platform details only
        v$entry <- NA_real_; v$stop <- NA_real_; v$limit <- NA_real_; v$exit <- NA_real_; v$pnl <- NA_real_
        msg("Ticket sent: size and platform details only. Entry, stop and target come from the open-position screen after the fill.", "warning")
      }
      log_evidence("CONFIRMED", list(confirmed_json = conf_json(v, ck), checks_json = as.character(jsonlite::toJSON(ck))))
      ev_ids <- rv$ev_id
      if (identical(kind, "open") && identical(k0, "open")) {   # bring in the platform details of the ticket read in the same batch (same instrument)
        for (it in rv$items) {
          if (identical(it$ev_id, rv$ev_id) || !identical(it$kind, "ticket") || is.null(it$ext) || !identical(it$ext$asset, v$asset)) next
          pick <- function(a, b) if (is.null(a) || length(a) != 1 || is.na(a) || (is.character(a) && !nzchar(a))) b else a
          for (k in c("contract", "account_type", "size_unit", "asset_raw", "deal_ref")) v[[k]] <- pick(v[[k]], it$ext[[k]])
          for (k in c("margin", "notional", "costs", "spread")) v[[k]] <- pick(v[[k]], it$ext[[k]])
          if (is.na(tr_or(v$deal_ref, NA)) && !is.null(it$ext$deal_ref)) v$deal_ref <- it$ext$deal_ref
          v$per_point <- isTRUE(v$per_point) || isTRUE(it$ext$per_point); ev_ids <- c(ev_ids, it$ev_id)
          msg("Platform details (contract type, margin, notional, costs, spread) were added from the ticket screenshot of the same instrument.", "message")
        }
      }
      v$screen <- tr_or(rv$parsed$screen_type, NA_character_)
      mark("sent"); bus$kind <- kind; bus$values <- v; bus$evidence_id <- ev_ids; bus$ts <- isolate(bus$ts) + 1
      tryCatch(shinydashboard::updateTabItems(session$rootScope(), "sidebar_menu", "trading_records"), error = function(e) NULL)
    }
    observeEvent(input$ex_save_only, {
      if (is.null(rv$img) || is.null(rv$ext)) { msg("Read a screenshot first.", "warning"); return() }
      ck <- checks(); v <- cur_ext()
      log_evidence("CONFIRMED", list(confirmed_json = conf_json(v, ck), checks_json = as.character(jsonlite::toJSON(ck))))
      mark("saved"); msg("Saved as evidence only. It is in the evidence log and is not linked to a trade yet.")
    })
    observeEvent(input$ex_send_open, send("open")); observeEvent(input$ex_send_close, send("close"))
    observeEvent(input$ex_send_auto, {
      k0 <- tr_or(rv$kind, "")
      if (k0 %in% c("open", "ticket")) send("open") else if (identical(k0, "close")) send("close")
      else msg("This screen is a record only (market quote or history). Use 'Save as evidence only'.", "warning")
    })
    observeEvent(input$ex_discard, {
      if (is.null(rv$img)) return(); log_evidence("DISCARDED"); mark("discarded"); rv$img <- NULL; rv$ext <- NULL; rv$parsed <- NULL; msg("Extraction discarded.")
    })

    output$log_table <- DT::renderDT({
      e <- evidence_df()
      if (!nrow(e)) return(DT::datatable(data.frame(Message = "No screenshots processed yet."), rownames = FALSE, options = list(dom = "t")))
      e <- e[order(e$saved_at, decreasing = TRUE), ]
      e$source <- vapply(e$extracted_json, function(j) tryCatch(tr_or(jsonlite::fromJSON(j)$source_device, ""), error = function(err) ""), "")
      DT::datatable(e[, c("evidence_id", "source", "kind", "status", "trade_id", "file_name", "model", "input_tokens", "output_tokens", "record_version")], rownames = FALSE, options = list(pageLength = 10, scrollX = TRUE))
    })
    output$dl_log <- downloadHandler(filename = function() paste0("trading_evidence_", format(Sys.Date()), ".csv"),
                                     content = function(file) write.csv(evidence_df(), file, row.names = FALSE, na = ""))
  })
}
