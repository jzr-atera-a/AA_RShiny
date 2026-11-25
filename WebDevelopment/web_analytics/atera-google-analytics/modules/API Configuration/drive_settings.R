# ---- page ------------------------------------------------------------
# id:          drive_settings
# tab label:   Google Drive
# main group:  API Configuration   (sidebar; see modules/_module_registry.yml)
# description: # modules/API Configuration/drive_settings.R - API Configuration > Google Drive: connection, folder scheme, catalogue
# functions:   drive_settings_ui(id), drive_settings_server(id, ...)
# --------------------------------------------------------------------

DRIVE_KEY  <- file.path(APP_DIR, "credentials", "drive-key.json")
DRIVE_CONF <- file.path(APP_DIR, "credentials", "drive-config.json")

load_drive_config <- function() {
  if (!file.exists(DRIVE_CONF)) return(NULL)
  tryCatch(jsonlite::fromJSON(DRIVE_CONF, simplifyVector = TRUE), error = function(e) NULL)
}
scheme_from_config <- function(conf) {
  s <- DEFAULT_SCHEME
  if (!is.null(conf$scheme)) for (k in names(s)) if (!is.null(conf$scheme[[k]])) s[[k]] <- conf$scheme[[k]]
  s
}

READER_SNIPPET <- paste(
  'source("drive_reader.R")   # copy this file from the dashboard folder',
  'd <- atera_drive("service-account.json", root = "<same folder link or ID>")',
  '',
  'cat <- atera_catalog(d)                  # every saved file (data frame)',
  'f   <- atera_latest(d, tab = "Overview", chart = "Traffic over time", format = "png")',
  'png <- atera_download(d, f$file_id)      # local path, e.g. for renderImage()',
  'fig <- atera_plotly(d, atera_latest(d, chart = "Traffic over time", format = "json")$file_id)',
  'dat <- atera_read_csv(d, atera_latest(d, chart = "Traffic over time", format = "csv")$file_id)',
  sep = "\n")

drive_settings_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(6,
        card("Connect Google Drive",
          sub = "Charts saved from any tab go into this folder, in a tidy folder tree that other apps can read.",
          radioButtons(ns("key_source"), "Service account key", inline = TRUE,
                       choices = c("Same key as Google Analytics" = "ga", "A different key" = "own")),
          conditionalPanel(sprintf("input['%s'] == 'own'", ns("key_source")),
            fileInput(ns("key"), NULL, accept = ".json", buttonLabel = "Browse...", placeholder = "Service account .json")),
          textInput(ns("root"), "Folder or shared drive to save into (link or ID)",
                    placeholder = "https://drive.google.com/drive/folders/..."),
          textInput(ns("subject"), "Act as this Google Workspace user (optional)",
                    placeholder = "only with domain-wide delegation, e.g. joseph.zr@atera-analytics.co.uk"),
          checkboxInput(ns("remember"), "Remember these settings on this computer", value = TRUE),
          div(class = "btn-row",
            actionButton(ns("connect"), "Connect & test", icon = icon("plug"), class = "btn-primary"),
            actionButton(ns("disconnect"), "Disconnect", icon = icon("power-off")),
            actionButton(ns("forget"), "Forget saved settings", icon = icon("trash")))
        )
      ),
      column(6, card("Connection check", sub = "Each step must pass before charts can be saved to Drive.",
                     uiOutput(ns("diag"))))
    ),
    fluidRow(
      column(7,
        card("Folder scheme",
          sub = "Folders are created automatically the first time a file goes into them. Use / between levels.",
          fluidRow(
            column(6, textInput(ns("app_name"), "Top folder name", DEFAULT_SCHEME$app_name)),
            column(6, checkboxInput(ns("latest"), "Also keep a fixed 'latest' copy of each chart", DEFAULT_SCHEME$latest))
          ),
          textInput(ns("folder_tpl"), "Folder for each saved file", DEFAULT_SCHEME$folder_template, width = "100%"),
          textInput(ns("file_tpl"), "File name (extension is added)", DEFAULT_SCHEME$file_template, width = "100%"),
          conditionalPanel(sprintf("input['%s']", ns("latest")),
            textInput(ns("latest_tpl"), "Folder for the 'latest' copies (file name is the chart name)",
                      DEFAULT_SCHEME$latest_template, width = "100%")),
          checkboxGroupInput(ns("default_formats"), "Formats ticked by default in the Save dialog",
                             choices = EXPORT_FORMATS, selected = DEFAULT_SCHEME$default_formats, inline = TRUE),
          div(class = "btn-row",
            actionButton(ns("save_scheme"), "Save scheme", icon = icon("save")),
            actionButton(ns("build_tree"), "Create folder tree now", icon = icon("sitemap")),
            actionButton(ns("reset_scheme"), "Reset to defaults", icon = icon("undo")))
        )
      ),
      column(5,
        card("Preview", sub = "Where a PNG of the Overview page's 'Traffic over time' chart would be saved right now",
             uiOutput(ns("preview"))),
        card("Name parts you can use",
          tags$table(class = "token-table",
            tags$tr(tags$td(tags$code("{app}")), tags$td("Top folder name")),
            tags$tr(tags$td(tags$code("{property}")), tags$td("GA4-515710306, or 'Demo data'")),
            tags$tr(tags$td(tags$code("{group}")), tags$td("Sidebar group, e.g. Audience")),
            tags$tr(tags$td(tags$code("{tab}")), tags$td("Page (tab), e.g. Visitors")),
            tags$tr(tags$td(tags$code("{chart}"), " ", tags$code("{chart_slug}")), tags$td("Chart title / traffic-over-time")),
            tags$tr(tags$td(tags$code("{format}")), tags$td("png, pdf, html...")),
            tags$tr(tags$td(tags$code("{year}"), " ", tags$code("{month}"), " ", tags$code("{day}")), tags$td("When it was saved")),
            tags$tr(tags$td(tags$code("{date}"), " ", tags$code("{time}"), " ", tags$code("{stamp}")), tags$td("2026-11-21 / 233400 / 20261121-233400")),
            tags$tr(tags$td(tags$code("{start}"), " ", tags$code("{end}"), " ", tags$code("{period}")), tags$td("Date range shown in the chart")),
            tags$tr(tags$td(tags$code("{mode}")), tags$td("live or demo"))
          ))
      )
    ),
    card("Saved files", sub = "From the shared catalogue _catalog/manifest.csv - this is what other apps read",
         right = div(class = "btn-row", dl_link(ns("dl_catalog")),
                     actionButton(ns("refresh"), "Refresh from Drive", icon = icon("sync"))),
         DT::DTOutput(ns("catalog"))),
    fluidRow(
      column(6, card("First-time setup",
        tags$ol(class = "setup-steps",
          tags$li("Google Cloud Console > APIs & Services > Library: enable ", tags$b("Google Drive API"),
                  " in the same project as your Analytics key (Atera 2)."),
          tags$li("In Google Drive create a ", tags$b("Shared drive"), " (e.g. 'Atera Analytics Reports'). ",
                  "Manage members > add the service account email as ", tags$b("Content manager"), "."),
          tags$li("Open the shared drive (or a folder inside it), copy the address bar, paste it above, press Connect & test."),
          tags$li("Every chart now has a Save button, and the header has 'Save charts' for the whole page.")
        ),
        note_box(kind = "warn", icon("exclamation-triangle"),
          " Why a shared drive: Google no longer gives service accounts their own storage, so they cannot create ",
          "files in an ordinary 'My Drive' folder even when it is shared with them. If your Google Workspace plan ",
          "has no shared drives, an admin can grant domain-wide delegation to the service account (scope ",
          tags$code(DRIVE_SCOPE), ") and you fill in 'Act as this Google Workspace user'."))),
      column(6, card("Reading these files from another Shiny app",
        tags$p("Copy ", tags$code("drive_reader.R"), " from this dashboard's folder into the other app. ",
               "Give that app's service account Viewer access to the same shared drive."),
        tags$pre(class = "code-snippet", READER_SNIPPET),
        tags$p(class = "ga-card-sub", "Tip: the fixed 'latest' copies keep the same file ID on every save, ",
               "so another app can link to one file and always get the newest chart.")))
    )
  )
}

drive_settings_server <- function(id, app, drive) {
  moduleServer(id, function(input, output, session) {

    diag <- reactiveVal(list())
    catalog <- reactiveVal(NULL)

    step <- function(status, title, detail = NULL) {
      diag(c(isolate(diag()), list(list(status = status, title = title, detail = detail))))
      cat(sprintf("[DRIVE] %s: %s%s\n", toupper(status), title, if (!is.null(detail)) paste0(" - ", detail) else ""))
    }

    # ---- scheme: inputs -> drive$scheme ------------------------------------------
    set_scheme_inputs <- function(s) {
      updateTextInput(session, "app_name", value = s$app_name)
      updateTextInput(session, "folder_tpl", value = s$folder_template)
      updateTextInput(session, "file_tpl", value = s$file_template)
      updateTextInput(session, "latest_tpl", value = s$latest_template)
      updateCheckboxInput(session, "latest", value = isTRUE(s$latest))
      updateCheckboxGroupInput(session, "default_formats", selected = s$default_formats)
    }
    current_scheme <- reactive({
      s <- list(
        app_name = sanitize_name(input$app_name %||% "") ,
        folder_template = trimws(input$folder_tpl %||% ""),
        file_template = trimws(input$file_tpl %||% ""),
        latest = isTRUE(input$latest),
        latest_template = trimws(input$latest_tpl %||% ""),
        default_formats = input$default_formats %||% character(0))
      if (!nzchar(s$app_name)) s$app_name <- DEFAULT_SCHEME$app_name
      if (!nzchar(s$folder_template)) s$folder_template <- DEFAULT_SCHEME$folder_template
      if (!nzchar(s$file_template)) s$file_template <- DEFAULT_SCHEME$file_template
      if (!nzchar(s$latest_template)) s$latest_template <- DEFAULT_SCHEME$latest_template
      s
    })
    observe({ drive$scheme <- current_scheme() })

    save_config <- function(root = NULL, key_source = NULL, subject = NULL) {
      old <- load_drive_config() %||% list()
      conf <- list(root = root %||% old$root %||% "", key_source = key_source %||% old$key_source %||% "ga",
                   subject = subject %||% old$subject %||% "", scheme = isolate(current_scheme()))
      tryCatch({
        dir.create(dirname(DRIVE_CONF), showWarnings = FALSE, recursive = TRUE)
        writeLines(jsonlite::toJSON(conf, auto_unbox = TRUE, pretty = TRUE), DRIVE_CONF)
        TRUE
      }, error = function(e) { cat("[DRIVE] Could not save settings:", conditionMessage(e), "\n"); FALSE })
    }

    # ---- connect ---------------------------------------------------------------
    key_for <- function(source) {
      if (identical(source, "own")) {
        if (!is.null(input$key)) return(input$key$datapath)
        if (file.exists(DRIVE_KEY)) return(DRIVE_KEY)
        stop("Upload the service account key to use for Drive.", call. = FALSE)
      }
      path <- isolate(app$conn$key_path) %||% (if (file.exists(CRED_KEY)) CRED_KEY else NULL)
      if (is.null(path)) stop("Connect Google Analytics first (API Configuration > Google Analytics), ",
                              "or choose 'A different key' and upload one.", call. = FALSE)
      path
    }

    do_connect <- function(source, root, subject, remember, scheme = NULL) {
      diag(list())
      drive$status <- "connecting"
      run <- function() {
        path <- tryCatch(key_for(source), error = function(e) { step("fail", "Service account key", conditionMessage(e)); NULL })
        if (is.null(path)) return(FALSE)
        info <- tryCatch(ga_read_key(path), error = function(e) { step("fail", "Service account key", conditionMessage(e)); NULL })
        if (is.null(info)) return(FALSE)
        step("ok", "Key file is a valid service account key", info$client_email)

        d <- tryCatch(drive_session(path, root, subject), error = function(e) {
          step("fail", "Google sign-in for Drive", conditionMessage(e)); NULL })
        if (is.null(d)) return(FALSE)
        step("ok", "Google issued a Drive access token",
             if (!is.null(d$conn$subject)) paste("acting as", d$conn$subject) else NULL)

        about <- tryCatch(drive_about(d), error = function(e) { step("fail", "Google Drive API", conditionMessage(e)); NULL })
        if (is.null(about)) return(FALSE)
        step("ok", "Google Drive API is enabled", paste("Signed in as", about$user$emailAddress %||% who_drive(d)))

        root_info <- tryCatch(drive_get_root(d), error = function(e) {
          step("fail", "Find the folder", conditionMessage(e)); NULL })
        if (is.null(root_info)) return(FALSE)
        if (!root_info$can_add) {
          step("fail", paste0("'", root_info$name, "' is read-only for this account"),
               paste0("Give ", who_drive(d), " Editor (folder) or Content manager (shared drive) access."))
          return(FALSE)
        }
        step("ok", paste0("Found '", root_info$name, "'"),
             if (root_info$shared_drive) "In a shared drive - good, files will use the shared drive's storage."
             else "In a 'My Drive'. Service accounts usually cannot create files here; the write test will tell.")

        test <- tryCatch({
          f <- drive_upload_bytes(d, charToRaw(paste("Atera Analytics write test", Sys.time())),
                                  "_atera_write_test.txt", "text/plain", parent = d$root_id)
          try(drive_delete(d, f$id), silent = TRUE)
          TRUE
        }, error = function(e) { step("fail", "Write test (create and delete a small file)", conditionMessage(e)); FALSE })
        if (!test) return(FALSE)
        step("ok", "Write test passed - the app can create files here")

        sch <- scheme %||% isolate(current_scheme())
        cat_folder <- tryCatch(drive_init_catalog(d, sch$app_name), error = function(e) {
          step("warn", "Could not create the catalogue folder", conditionMessage(e)); NULL })
        if (!is.null(cat_folder)) step("ok", "Catalogue ready", paste0(cat_folder$path, "/manifest.csv"))

        drive$d <- d
        drive$root_name <- root_info$name
        drive$root_link <- root_info$link
        drive$status <- "connected"
        drive$tick <- isolate(drive$tick) + 1

        if (remember) {
          if (identical(source, "own") && !is.null(input$key)) {
            dir.create(dirname(DRIVE_KEY), showWarnings = FALSE, recursive = TRUE)
            file.copy(input$key$datapath, DRIVE_KEY, overwrite = TRUE)
          }
          if (save_config(root, source, subject %||% "")) step("ok", "Settings saved - Drive reconnects automatically next time")
        }
        showNotification("Google Drive connected. Use the Save buttons on any chart.", type = "message")
        TRUE
      }
      ok <- tryCatch(run(), error = function(e) { step("fail", "Unexpected error", conditionMessage(e)); FALSE })
      if (!ok) {
        drive$status <- "off"; drive$d <- NULL
        showNotification("Google Drive connection failed - see the Connection check panel.", type = "error", duration = 8)
      }
      invisible(ok)
    }

    # Restore saved settings; connect automatically when a key is available.
    observe(isolate({
      conf <- load_drive_config()
      if (is.null(conf)) return()
      s <- scheme_from_config(conf)
      set_scheme_inputs(s)
      drive$scheme <- s
      updateRadioButtons(session, "key_source", selected = conf$key_source %||% "ga")
      updateTextInput(session, "root", value = conf$root %||% "")
      updateTextInput(session, "subject", value = conf$subject %||% "")
      has_key <- if (identical(conf$key_source, "own")) file.exists(DRIVE_KEY) else file.exists(CRED_KEY)
      if (nzchar(conf$root %||% "") && has_key) {
        cat("[DRIVE] Saved settings found - connecting automatically\n")
        do_connect(conf$key_source %||% "ga", conf$root, conf$subject, remember = FALSE, scheme = s)
      }
    }))

    observeEvent(input$connect, {
      do_connect(input$key_source, input$root, input$subject, isTRUE(input$remember))
    })
    observeEvent(input$disconnect, {
      drive$d <- NULL; drive$status <- "off"; diag(list())
      showNotification("Google Drive disconnected.", type = "message")
    })
    observeEvent(input$forget, {
      gone <- c(DRIVE_CONF, DRIVE_KEY)[file.exists(c(DRIVE_CONF, DRIVE_KEY))]
      if (length(gone)) file.remove(gone)
      showNotification(if (length(gone)) "Saved Drive settings removed." else "There were no saved Drive settings.",
                       type = "message")
    })

    # ---- scheme buttons ---------------------------------------------------------------
    observeEvent(input$save_scheme, {
      bad <- unique(c(unknown_tokens(input$folder_tpl), unknown_tokens(input$file_tpl), unknown_tokens(input$latest_tpl)))
      if (length(bad)) {
        showNotification(paste("Unknown name part(s):", paste0("{", bad, "}", collapse = ", ")), type = "error")
        return()
      }
      if (save_config()) showNotification("Folder scheme saved.", type = "message")
    })
    observeEvent(input$reset_scheme, {
      set_scheme_inputs(DEFAULT_SCHEME)
      showNotification("Scheme reset to defaults (press Save scheme to keep it).", type = "message")
    })

    observeEvent(input$build_tree, {
      d <- drive$d
      if (is.null(d)) { showNotification("Connect Google Drive first.", type = "warning"); return() }
      sch <- current_scheme()
      prop <- if (identical(app$mode, "live")) paste0("GA4-", app$property_id) else "Demo data"
      now <- Sys.time()
      paths <- unique(unlist(lapply(names(TAB_LABELS), function(tab) {
        meta <- list(app = sch$app_name, property = prop, group = TAB_GROUPS[[tab]], tab = TAB_LABELS[[tab]],
                     chart = "", mode = app$mode, start = Sys.Date(), end = Sys.Date())
        tk <- scheme_tokens(meta, "", now)
        c(paste(resolve_folder(template_prefix(sch$folder_template), tk), collapse = "/"),
          if (isTRUE(sch$latest)) paste(resolve_folder(template_prefix(sch$latest_template), tk), collapse = "/"))
      })))
      paths <- paths[nzchar(paths)]
      before <- d$created_count %||% 0
      res <- tryCatch({
        withProgress(message = "Creating folders in Google Drive", value = 0, {
          for (i in seq_along(paths)) {
            drive_ensure_path(d, strsplit(paths[i], "/", fixed = TRUE)[[1]])
            incProgress(1 / length(paths), detail = paths[i])
          }
          drive_init_catalog(d, sch$app_name)
        })
        TRUE
      }, error = function(e) { showNotification(conditionMessage(e), type = "error", duration = NULL); FALSE })
      if (res) {
        made <- (d$created_count %||% 0) - before
        showNotification(sprintf("Folder tree ready: %d path(s) checked, %d new folder(s) created. ",
                                 length(paths), made), type = "message", duration = 8)
        cat("[DRIVE] Folder tree ensured:\n", paste(" -", paths, collapse = "\n"), "\n")
      }
    })

    # ---- outputs ------------------------------------------------------------------
    output$diag <- renderUI({
      steps <- diag()
      if (length(steps) == 0) {
        return(note_box(icon("info-circle"),
          if (identical(drive$status, "connected")) paste0(" Connected to '", drive$root_name, "'.")
          else " Not connected. Charts can still be downloaded to your computer from the Save buttons."))
      }
      ico <- c(ok = "check-circle", warn = "exclamation-triangle", fail = "times-circle")
      tagList(
        tags$ul(class = "diag", lapply(steps, function(s) {
          tags$li(class = s$status, icon(ico[[s$status]]),
                  div(div(class = "diag-title", s$title), if (!is.null(s$detail)) div(class = "diag-detail", s$detail)))
        })),
        if (identical(drive$status, "connected") && !is.null(drive$root_link))
          tags$p(tags$a(href = drive$root_link, target = "_blank", icon("external-link-alt"), " Open the folder in Google Drive"))
      )
    })

    output$preview <- renderUI({
      s <- current_scheme()
      bad <- unique(c(unknown_tokens(s$folder_template), unknown_tokens(s$file_template),
                      if (s$latest) unknown_tokens(s$latest_template)))
      meta <- list(app = s$app_name,
                   property = if (identical(app$mode, "live")) paste0("GA4-", app$property_id) else "Demo data",
                   group = lookup(TAB_GROUPS, "overview", "Overview & Monitoring"),
                   tab = lookup(TAB_LABELS, "overview", "Overview"), chart = "Traffic over time", mode = app$mode,
                   start = Sys.Date() - 28, end = Sys.Date() - 1)
      tk <- scheme_tokens(meta, "png", Sys.time())
      segs <- resolve_folder(s$folder_template, tk)
      root <- drive$root_name %||% "(your folder)"
      tagList(
        tags$div(class = "tree",
          lapply(seq_along(c(root, segs)), function(i) {
            tags$div(class = "tree-row", style = sprintf("padding-left:%dpx", (i - 1) * 14),
                     icon("folder"), " ", c(root, segs)[i])
          }),
          tags$div(class = "tree-row file", style = sprintf("padding-left:%dpx", (length(segs) + 1) * 14),
                   icon("file-image"), " ", resolve_file(s$file_template, tk, "png"))),
        if (s$latest) tags$p(class = "ga-card-sub", "Latest copy: ",
          tags$code(paste(c(resolve_folder(s$latest_template, tk), latest_file_name(tk, "png")), collapse = "/"))),
        if (length(bad)) note_box(kind = "warn", "Unknown name part(s): ", paste0("{", bad, "}", collapse = ", "),
                                  " - they will be kept as typed.")
      )
    })

    load_catalog <- function() {
      d <- drive$d
      if (is.null(d)) return(NULL)
      tryCatch(drive_read_manifest(d, current_scheme()$app_name)$df, error = function(e) {
        showNotification(conditionMessage(e), type = "error"); NULL })
    }
    observeEvent(list(input$refresh, drive$tick), { catalog(load_catalog()) }, ignoreInit = FALSE)

    output$catalog <- DT::renderDT({
      df <- catalog()
      validate(need(identical(drive$status, "connected"), "Connect Google Drive to see the catalogue."),
               need(!is.null(df) && nrow(df) > 0, "No charts saved yet. Use the Save button on any chart."))
      df <- df[rev(seq_len(nrow(df))), , drop = FALSE]
      out <- data.frame(
        Saved = df$saved_at, Tab = df$tab, Chart = df$chart, Format = toupper(df$format),
        Mode = df$data_mode, Folder = df$folder_path,
        File = ifelse(nzchar(df$web_view_link),
                      sprintf('<a href="%s" target="_blank">%s</a>', df$web_view_link, htmltools::htmlEscape(df$file_name)),
                      htmltools::htmlEscape(df$file_name)),
        stringsAsFactors = FALSE)
      DT::datatable(out, rownames = FALSE, escape = FALSE, class = "compact hover",
                    options = list(pageLength = 10, dom = "ftp", scrollX = TRUE, order = list()))
    })
    output$dl_catalog <- csv_handler(catalog, "drive_catalog")
  })
}
