# modules/gdrive_export.R
# API Configuration > Google Drive: connect, choose the folder and the scheme. And the "save to Google Drive" pop-up that the
# small cloud button on every chart, diagram, picture and table opens (www/js/gdrive_export.js). Files go to
#   <root> / <menu group> / <tab> / <sub-tab ...> / <YYYY> / <YYYY-MM-DD> / HHMMSS_<title>.<ext>
# with an index (_index/lat_u3_drive_index.csv) that other R Shiny apps read. Each save is also logged in BigQuery (cc_events,
# DRIVE_EXPORT). Keys stay in memory only.

gd_client <- gd_make_client()

# start-up: a key and folder from the environment or the local key folder connect on their own
gd_auto_connect <- function(gd = gd_client) {
  if (gd$connected()) return(invisible(FALSE))
  dir <- tryCatch(tr_cred_dir(), error = function(e) "")
  one <- function(f) if (nzchar(dir) && file.exists(file.path(dir, f))) { x <- trimws(readLines(file.path(dir, f), warn = FALSE)); x <- x[nzchar(x)]; if (length(x)) x[1] else "" } else ""
  folder <- Sys.getenv("GDRIVE_FOLDER_ID", one("gdrive_folder_1_line.txt"))
  root <- Sys.getenv("GDRIVE_ROOT_NAME", gd$root_name)
  local_dir <- Sys.getenv("GDRIVE_LOCAL_DIR", "")
  key <- Sys.getenv("GDRIVE_KEY_FILE", "")
  if (!nzchar(key) && nzchar(dir) && dir.exists(dir)) { k <- list.files(dir, pattern = "drive.*\\.json$", full.names = TRUE, ignore.case = TRUE); if (length(k)) key <- k[1] }
  ok <- tryCatch({
    if (nzchar(local_dir)) { gd$connect(gd_local_backend(), local_dir, "folder", who = "this computer", root_name = root); TRUE }
    else if (nzchar(key) && file.exists(key) && nzchar(gd_parse_id(folder))) { t <- gd_sa_token(json_path = key); gd$connect(gd_api_backend(t$token), gd_parse_id(folder), "service", t$who, t$project, root); TRUE }
    else FALSE
  }, error = function(e) { cat("[Google Drive] automatic connection failed:", conditionMessage(e), "\n"); gd$msg <- paste("Automatic connection failed:", conditionMessage(e)); FALSE })
  if (ok) cat("[Google Drive]", gd$msg, "\n")
  invisible(ok)
}

gdrive_config_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$h3("Google Drive: save charts, diagrams and tables for other apps"),
    tags$div(style = "background:#eef6f5; border:1px solid #b2e0db; border-radius:8px; padding:10px 12px; margin-bottom:12px; font-size:12.5px; color:#134e4a; line-height:1.6;",
      "Once connected, every chart, diagram, picture and table in the app gets a small ", icon("cloud-arrow-up"), " button (top-left of charts, bottom-right of tables). ",
      "It saves the item as ", tags$b("PNG, JPEG, SVG, PDF, animated GIF, interactive HTML, chart data (JSON) or CSV"), " into a folder for its ",
      tags$b("menu group / tab / sub-tab / year / date"), ". The folders are made the first time a file needs them. The pop-up can also save ", tags$b("every item on the page"), " in one go. ",
      "An index of every file (", tags$code(paste0("_index/", gd_index_name)), ") lets other R Shiny apps find and read them. Keys are never saved or shown."),
    fluidRow(
      box(title = "Connection", status = "primary", solidHeader = TRUE, width = 5,
        radioButtons(ns("mode"), "How to connect:", choices = c("Service-account key (on the server and on your PC)" = "service",
                                                                "My Google account (only when the app runs on your PC)" = "oauth",
                                                                "Google Drive for desktop folder (files sync on their own)" = "folder"), selected = "service"),
        conditionalPanel(sprintf("input['%s'] == 'service'", ns("mode")),
          uiOutput(ns("auto_key")),
          fileInput(ns("key_file"), "Service-account key (.json):", accept = ".json"),
          textAreaInput(ns("key_text"), "or paste the key:", rows = 3, placeholder = "{ \"type\": \"service_account\", ... }"),
          checkboxInput(ns("use_bq"), "Use the BigQuery key the app already found (turn on the Google Drive API in the same Google Cloud project)", FALSE)),
        conditionalPanel(sprintf("input['%s'] == 'oauth'", ns("mode")),
          textInput(ns("email"), "Google account email (optional):", ""),
          tags$p(style = "font-size:11.5px; color:#64748b;", "A browser window opens to sign in. Leave the folder link empty to save into My Drive.")),
        conditionalPanel(sprintf("input['%s'] == 'folder'", ns("mode")),
          textInput(ns("local_dir"), "Folder on this computer:", if (.Platform$OS.type == "windows") "G:/My Drive" else path.expand("~/Google Drive/My Drive")),
          tags$p(style = "font-size:11.5px; color:#64748b;", "Google Drive for desktop puts your Drive in a folder such as G:/My Drive. Files written there are uploaded by Drive itself.")),
        conditionalPanel(sprintf("input['%s'] != 'folder'", ns("mode")),
          textInput(ns("folder"), "Drive folder to save into (link or id):", Sys.getenv("GDRIVE_FOLDER_ID", ""), placeholder = "https://drive.google.com/drive/folders/...")),
        textInput(ns("root_name"), "Main folder made inside it:", Sys.getenv("GDRIVE_ROOT_NAME", "LAT U3 Trading Desk")),
        actionButton(ns("connect"), "Connect & prepare folders", icon = icon("plug"), class = "btn-primary", width = "100%"),
        tags$div(style = "margin-top:6px;", actionButton(ns("test"), "Test: save a small file", icon = icon("stethoscope")), actionButton(ns("disconnect"), "Disconnect", icon = icon("power-off"))),
        uiOutput(ns("conn_msg")),
        tags$details(style = "margin-top:10px; font-size:12px;", tags$summary(style = "cursor:pointer; font-weight:700;", "Setting up a service-account key (once)"),
          tags$ol(style = "padding-left:18px; line-height:1.6;",
            tags$li("console.cloud.google.com > your project (e.g. atera-2) > APIs & Services > Library > ", tags$b("Google Drive API > Enable"), "."),
            tags$li("IAM & Admin > Service Accounts: use the BigQuery one or make a new one; Keys > Add key > JSON."),
            tags$li("A service account has no storage of its own, so make a ", tags$b("Shared Drive"), " (or use one), and add the key's email (shown above once loaded) as ", tags$b("Content manager"), "."),
            tags$li("Open the Shared Drive (or a folder in it) and paste its link above. On a PC you can put the key in the key folder as ", tags$code("gdrive_*.json"), " and the link in ", tags$code("gdrive_folder_1_line.txt"), "; on the server set ", tags$code("GDRIVE_KEY_FILE"), " and ", tags$code("GDRIVE_FOLDER_ID"), "."),
            tags$li("Other apps read the files with the same key (or any account the Shared Drive is shared with).")))),
      box(title = "Status, folder scheme and formats", status = "info", solidHeader = TRUE, width = 7,
        uiOutput(ns("status")),
        tags$hr(),
        fluidRow(
          column(6, selectInput(ns("dates"), "Date folders under each tab:", c("Year / date (2026 / 2026-11-22)" = "year_date", "Month / date (2026-11 / 2026-11-22)" = "month_date",
                                                                              "Date only (2026-11-22)" = "date", "No date folders" = "none"), "year_date")),
          column(6, checkboxGroupInput(ns("kinds"), "Show the save button on:", choices = setNames(names(gd_kind_names), gd_kind_names), selected = names(gd_kind_names), inline = TRUE))),
        checkboxGroupInput(ns("formats"), "Formats ticked in the pop-up:", choices = gd_formats, selected = c("png", "pdf", "html", "json"), inline = TRUE),
        checkboxInput(ns("offline"), "HTML files work without internet (adds about 3.5 MB of Plotly to each chart page)", FALSE),
        actionButton(ns("save"), "Save settings", icon = icon("save"), class = "btn-success"), uiOutput(ns("save_msg"), inline = TRUE),
        tags$hr(),
        tags$div(style = "font-weight:700; color:#002C3C;", "Folder scheme"),
        uiOutput(ns("scheme")),
        tags$details(tags$summary(style = "cursor:pointer; font-weight:700; margin-top:8px;", "Reading the files from another R Shiny app"),
          tags$pre(style = "font-size:11.5px; white-space:pre-wrap;", paste0(
            "library(googledrive)\ndrive_auth(path = Sys.getenv(\"GDRIVE_KEY_FILE\"))   # a key that can read the Shared Drive\n",
            "ix  <- drive_find(\"", gd_index_name, "\", shared_drive = \"<your Shared Drive>\")\n",
            "tab <- read.csv(text = drive_read_string(ix$id[1]))          # one row per file: group, tab, sub_tabs, title, format, file_id, link\n",
            "f   <- subset(tab, tab == \"Trading Desk\" & format == \"json\") |> tail(1)\n",
            "fig <- jsonlite::fromJSON(drive_read_string(as_id(f$file_id)), simplifyVector = FALSE)\n",
            "plotly::as_widget(list(data = fig$data, layout = fig$layout))   # the same chart, interactive\n",
            "# pictures: drive_download(as_id(id), path = tempfile(fileext = \".png\"))"))),
        tags$hr(),
        tags$div(style = "font-weight:700; color:#002C3C; margin-bottom:4px;", "Latest files saved"),
        DT::DTOutput(ns("recent"))))
  )
}

gdrive_config_server <- function(id, gd = gd_client, store = NULL) {
  moduleServer(id, function(input, output, session) {
    tick <- reactivePoll(1500, session, function() gd$tick, function() gd$tick)
    msg <- reactiveVal(NULL)
    say <- function(ok, t) msg(tags$div(style = sprintf("margin-top:8px; color:%s;", if (ok) "#15803d" else "#b91c1c"), icon(if (ok) "check-circle" else "times-circle"), " ", t))
    bq_key <- function() { k <- Sys.getenv("ATERA_BQ_KEY_FILE", Sys.getenv("GOOGLE_APPLICATION_CREDENTIALS", "")); if (nzchar(k) && file.exists(k)) return(k)
      lc <- tryCatch(tr_local_credentials(), error = function(e) list()); p <- tr_or(lc$json_path, NA); if (!is.na(p) && file.exists(p)) p else "" }
    output$auto_key <- renderUI({ k <- bq_key()
      if (nzchar(k)) tags$div(style = "background:#ecfdf5; border:1px solid #a7f3d0; color:#065f46; border-radius:8px; padding:6px 10px; margin-bottom:8px; font-size:12px;",
        icon("key"), sprintf(" A BigQuery key was found (%s). Tick the box below to use it for Drive too.", basename(k))) })

    # settings kept in BigQuery (no secrets)
    observe({ if (is.null(store)) return(); s <- tryCatch(store$current("settings"), error = function(e) NULL); if (is.null(s) || !nrow(s)) return()
      v <- function(k) { x <- s$setting_value[s$setting_key == k]; if (length(x) && !is.na(x[1]) && nzchar(x[1])) x[1] else NA }
      if (!is.na(v("gdrive_mode"))) updateRadioButtons(session, "mode", selected = v("gdrive_mode"))
      if (!is.na(v("gdrive_folder")) && !nzchar(isolate(input$folder))) updateTextInput(session, "folder", value = v("gdrive_folder"))
      if (!is.na(v("gdrive_root_name"))) updateTextInput(session, "root_name", value = v("gdrive_root_name"))
      if (!is.na(v("gdrive_local_dir"))) updateTextInput(session, "local_dir", value = v("gdrive_local_dir"))
      if (!is.na(v("gdrive_dates"))) { updateSelectInput(session, "dates", selected = v("gdrive_dates")); gd$dates <- v("gdrive_dates") }
      if (!is.na(v("gdrive_formats"))) { f <- strsplit(v("gdrive_formats"), ",")[[1]]; updateCheckboxGroupInput(session, "formats", selected = f); gd$formats <- f }
      if (!is.na(v("gdrive_kinds"))) { k <- strsplit(v("gdrive_kinds"), ",")[[1]]; updateCheckboxGroupInput(session, "kinds", selected = k); gd$kinds <- k }
      if (!is.na(v("gdrive_offline"))) { updateCheckboxInput(session, "offline", value = identical(v("gdrive_offline"), "TRUE")); gd$offline_html <- identical(v("gdrive_offline"), "TRUE") }
    })
    observeEvent(tick(), { if (gd$connected() && gd$mode %in% c("service", "oauth", "folder")) updateRadioButtons(session, "mode", selected = gd$mode) }, once = TRUE)
    observeEvent(input$dates, { gd$dates <- input$dates; gd$bump() }, ignoreInit = TRUE)
    observeEvent(input$formats, { gd$formats <- input$formats %||% character(0) }, ignoreInit = TRUE, ignoreNULL = FALSE)
    observeEvent(input$kinds, { gd$kinds <- input$kinds %||% character(0); gd$bump() }, ignoreInit = TRUE, ignoreNULL = FALSE)
    observeEvent(input$offline, { gd$offline_html <- isTRUE(input$offline) }, ignoreInit = TRUE)

    observeEvent(input$connect, withProgress(message = "Connecting to Google Drive and preparing the folders...", value = 0.3, {
      r <- tryCatch({
        if (input$mode == "folder") { d <- trimws(input$local_dir); if (!nzchar(d)) stop("Type the folder on this computer.", call. = FALSE)
          gd$connect(gd_local_backend(), d, "folder", "this computer", root_name = input$root_name) }
        else {
          t <- if (input$mode == "oauth") gd_oauth_token(input$email)
               else if (isTRUE(input$use_bq)) { k <- bq_key(); if (!nzchar(k)) stop("No BigQuery key was found: load the key file.", call. = FALSE); gd_sa_token(json_path = k) }
               else gd_sa_token(json_path = input$key_file$datapath, json_text = input$key_text)
          incProgress(0.3)
          fid <- gd_parse_id(input$folder)
          if (nzchar(trimws(input$folder)) && !nzchar(fid)) stop("That does not look like a Drive folder link.", call. = FALSE)
          gd$connect(gd_api_backend(t$token), fid, input$mode, t$who, t$project, root_name = input$root_name) }
        updateTextAreaInput(session, "key_text", value = "")
        TRUE }, error = function(e) { say(FALSE, conditionMessage(e)); FALSE })
      if (isTRUE(r)) say(TRUE, gd$msg)
    }))
    observeEvent(input$test, withProgress(message = "Saving a test file to Google Drive...", value = 0.4, {
      if (!gd$connected()) return(say(FALSE, "Connect first."))
      f <- tempfile(fileext = ".txt"); writeLines(c("LAT U3 Trading Desk: connection test", format(Sys.time(), tz = "UTC", usetz = TRUE)), f)
      r <- tryCatch({ x <- gd$save(c(connection_test.txt = f), c("_index", "tests"), list(title = "Connection test", kind = "test", path = list("API Configuration", "Google Drive")))
        sprintf("Test file saved in %s.", x$folder$path) }, error = function(e) e)
      if (inherits(r, "error")) say(FALSE, conditionMessage(r)) else say(TRUE, r)
    }))
    observeEvent(input$disconnect, { gd$disconnect(); say(TRUE, "Disconnected. The save buttons are hidden.") })
    observeEvent(input$save, {
      df <- data.frame(setting_key = c("gdrive_mode", "gdrive_folder", "gdrive_root_name", "gdrive_local_dir", "gdrive_dates", "gdrive_formats", "gdrive_kinds", "gdrive_offline"),
                       setting_value = c(input$mode, gd_parse_id(input$folder), input$root_name, input$local_dir, input$dates, paste(input$formats, collapse = ","),
                                         paste(input$kinds, collapse = ","), as.character(isTRUE(input$offline))), stringsAsFactors = FALSE)
      where <- if (is.null(store)) "this session" else tryCatch(store$write("settings", df), error = function(e) paste("not saved:", conditionMessage(e)))
      output$save_msg <- renderUI(tags$span(style = "color:#27ae60; margin-left:8px;", icon("check"), sprintf(" Saved (%s). Keys are never saved.", where)))
    })
    output$conn_msg <- renderUI(msg())
    output$status <- renderUI({ tick()
      row <- function(k, v) tags$tr(tags$td(style = "padding:2px 10px 2px 0; color:#64748b;", k), tags$td(style = "padding:2px 0;", v))
      if (!gd$connected()) return(tags$div(style = "color:#92400e; background:#fffbeb; border:1px solid #fde68a; border-radius:8px; padding:8px 10px;",
        icon("circle-exclamation"), " Not connected. ", if (nzchar(gd$msg)) gd$msg else "Choose how to connect and press Connect."))
      lk <- gd_or(gd$root$webViewLink, "")
      tags$table(style = "font-size:12.5px;",
        row("Connected with", sprintf("%s%s", c(service = "service-account key", oauth = "Google account", folder = "Google Drive for desktop folder")[[gd$mode]], if (nzchar(gd$who)) paste0(" (", gd$who, ")") else "")),
        row("Main folder", if (grepl("^https?://", lk)) tags$a(href = lk, target = "_blank", gd$root_name) else tags$code(lk)),
        row("This app run", sprintf("%d file(s) saved, %d folder(s) made", gd$saved, gd$folders_made)),
        row("Files in the index", if (is.null(gd$index)) 0 else nrow(gd$index)))
    })
    output$scheme <- renderUI({ tick(); d <- gd_folder_parts(c("Trade Journal", "Trading Desk", "B. Analyse & Place"), Sys.time(), input$dates %||% "year_date")
      tags$div(class = "gdx-path", paste(c(gd$root_name, d, paste0(gd_file_base("Price chart with patterns"), ".png")), collapse = " / "), tags$br(),
               paste(c(gd$root_name, "_index", gd_index_name), collapse = " / ")) })
    output$recent <- DT::renderDT({ tick(); x <- gd$index
      if (is.null(x) || !nrow(x)) return(DT::datatable(data.frame(Note = "Nothing saved yet."), rownames = FALSE, options = list(dom = "t")))
      x <- utils::tail(x, 60); x <- x[rev(seq_len(nrow(x))), , drop = FALSE]
      lk <- ifelse(grepl("^https?://", x$link), sprintf("<a href='%s' target='_blank'>open</a>", x$link), htmltools::htmlEscape(x$link))
      DT::datatable(data.frame(Saved = x$saved_at_utc, Folder = sub("^[^/]+/ ", "", x$folder_path), File = x$file_name, Open = lk, stringsAsFactors = FALSE),
                    rownames = FALSE, escape = -4, options = list(pageLength = 8, dom = "tp", scrollX = TRUE)) })
  })
}

# ---- the pop-up and the saving, for every page of the app ------------------------------------------------------
gdrive_export_server <- function(input, output, session, gd = gd_client, store = NULL) {
  pending <- reactiveVal(NULL); batch <- new.env(); session$userData$gdx_batch <- batch
  last <- reactiveVal("")
  observe({ invalidateLater(2500); st <- paste(gd$connected(), paste(gd$kinds, collapse = ","))
    if (!identical(st, isolate(last()))) { last(st); session$sendCustomMessage("gdx_state", list(on = gd$connected(), kinds = as.list(gd$kinds))) } })
  log_bq <- function(p, res, formats) {
    if (is.null(store)) return(invisible())
    tryCatch(store$write("events", data.frame(event_id = cc_id("DRV"), trade_id = NA_character_, event_type = "DRIVE_EXPORT", note = res$folder$path,
      request_json = cc_json(list(title = p$title, kind = p$kind, path = unlist(p$path), formats = formats)),
      response_json = cc_json(lapply(res$files, function(f) list(id = f$id, link = f$link, format = f$format, bytes = f$size))), stringsAsFactors = FALSE)),
      error = function(e) NULL)
  }
  save_one <- function(p, formats, title = p$title) {
    p$title <- gd_or(trimws(title), p$title); when <- Sys.time()
    b <- gd_build_files(p, formats, base = gd_file_base(p$title, when), offline_html = gd$offline_html)
    on.exit(unlink(dirname(unname(b$files)), recursive = TRUE), add = TRUE)
    if (!length(b$files)) stop(paste("Nothing could be made:", paste(b$skipped, collapse = "; ")), call. = FALSE)
    res <- gd$save(b$files, gd_folder_parts(p$path, when, gd$dates), list(title = p$title, kind = p$kind, path = p$path, export_id = cc_id("DRV")))
    log_bq(p, res, formats); res$skipped <- b$skipped; res
  }
  done_note <- function(res, n_items = 1) {
    lk <- gd_or(res$folder$link, "")
    showNotification(duration = 12, type = if (length(res$skipped)) "warning" else "message", tags$div(
      icon("cloud-arrow-up"), sprintf(" %d file(s)%s saved to ", length(res$files), if (n_items > 1) sprintf(" from %d items", n_items) else ""),
      if (grepl("^https?://", lk)) tags$a(href = lk, target = "_blank", res$folder$path) else tags$code(res$folder$path),
      if (length(res$skipped)) tags$div(style = "font-size:11.5px;", "Not made: ", paste(res$skipped, collapse = "; "))))
  }
  observeEvent(input$gdx_err, showNotification(paste("The item could not be captured:", input$gdx_err), type = "error"))
  observeEvent(input$gdx_click, {
    p <- input$gdx_click
    if (!gd$connected()) return(showNotification("Google Drive is not connected: API Configuration > Google Drive.", type = "warning"))
    pending(p); kind <- gd_or(p$kind, "plotly"); can <- gd_kind_formats[[kind]]
    sel <- intersect(gd$formats, can); if (!length(sel)) sel <- can[1]
    parts <- gd_folder_parts(p$path, Sys.time(), gd$dates)
    showModal(modalDialog(title = tagList(icon("cloud-arrow-up"), sprintf(" Save this %s to Google Drive", tolower(sub("s$", "", gd_kind_names[[kind]])))), easyClose = TRUE, size = "m",
      textInput("gdx_title", "Name:", value = p$title, width = "100%"),
      checkboxGroupInput("gdx_fmt", "Formats:", choices = gd_formats[gd_formats %in% can], selected = sel, inline = TRUE),
      tags$div(style = "font-size:12px; color:#64748b; margin-bottom:4px;", "Folder (made if it does not exist yet):"),
      tags$div(class = "gdx-path", paste(c(gd$root_name, parts), collapse = " / ")),
      if (kind == "table") tags$p(style = "font-size:11.5px; color:#64748b; margin-top:6px;", "Tables are saved with the rows shown on screen: show more rows first to save them all."),
      footer = tagList(modalButton("Cancel"),
        actionButton("gdx_all_btn", "Save every item on this page", icon = icon("layer-group")),
        actionButton("gdx_save", "Save", icon = icon("cloud-arrow-up"), class = "btn-primary"))))
  })
  observeEvent(input$gdx_save, {
    p <- pending(); req(p); fm <- input$gdx_fmt
    if (!length(fm)) return(showNotification("Tick at least one format.", type = "warning"))
    removeModal()
    withProgress(message = "Saving to Google Drive...", detail = sprintf("%s: %s", p$title, paste(toupper(fm), collapse = ", ")), value = 0.3, {
      r <- tryCatch(save_one(p, fm, input$gdx_title), error = function(e) e)
      if (inherits(r, "error")) showNotification(paste("Not saved:", conditionMessage(r)), type = "error", duration = 15) else done_note(r)
    })
  })
  # every item on the page: the browser sends them one by one and waits for each answer
  observeEvent(input$gdx_all_btn, {
    fm <- input$gdx_fmt; if (!length(fm)) return(showNotification("Tick at least one format.", type = "warning"))
    removeModal(); id <- cc_id("BAT"); batch$id <- id; batch$fm <- fm; batch$files <- 0L; batch$items <- 0L; batch$skipped <- character(0); batch$folders <- character(0); batch$last <- NULL
    session$sendCustomMessage("gdx_all", list(id = id, formats = as.list(fm), kinds = as.list(gd$kinds)))
  })
  observeEvent(input$gdx_item, {
    m <- input$gdx_item; if (!identical(m$batch, batch$id)) return()
    if (isTRUE(m$start)) {
      if (!isTRUE(m$n > 0)) return(showNotification("No charts, diagrams, pictures or tables are showing on this page.", type = "warning"))
      showNotification(id = "gdx_prog", duration = NULL, closeButton = FALSE, type = "message", sprintf("Saving %d item(s) on this page to Google Drive...", m$n))
      return(session$sendCustomMessage("gdx_ack", list(batch = m$batch, start = TRUE)))
    }
    if (isTRUE(m$done)) {
      removeNotification("gdx_prog")
      if (!is.null(batch$last)) { r <- batch$last; r$files <- rep(list(NULL), batch$files); r$skipped <- batch$skipped
        if (length(unique(batch$folders)) > 1) { r$folder$path <- sprintf("%d folders under %s", length(unique(batch$folders)), gd$root_name); r$folder$link <- gd_or(gd$root$webViewLink, "") }
        done_note(r, batch$items) }
      return()
    }
    showNotification(id = "gdx_prog", duration = NULL, closeButton = FALSE, type = "message",
      tags$div(icon("cloud-arrow-up"), sprintf(" Saving %d of %d to Google Drive: %s", m$i, m$n, gd_or(m$title, "")),
               tags$div(style = "height:6px; background:#e2e8f0; border-radius:3px; margin-top:6px;", tags$div(style = sprintf("height:6px; width:%d%%; background:#008A82; border-radius:3px;", round(100 * m$i / m$n))))))
    r <- tryCatch(save_one(m, unlist(m$formats)), error = function(e) e)
    if (inherits(r, "error")) batch$skipped <- c(batch$skipped, sprintf("%s (%s)", m$title, conditionMessage(r)))
    else { batch$files <- batch$files + length(r$files); batch$items <- batch$items + 1L; batch$last <- r; batch$folders <- c(batch$folders, r$folder$path)
      if (length(r$skipped)) batch$skipped <- c(batch$skipped, paste0(m$title, ": ", paste(r$skipped, collapse = ", "))) }
    session$sendCustomMessage("gdx_ack", list(batch = m$batch, i = m$i))
  })
  invisible(list(batch = batch))
}
