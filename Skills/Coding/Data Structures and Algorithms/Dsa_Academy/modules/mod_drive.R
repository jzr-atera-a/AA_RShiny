# modules/mod_drive.R — APIs › Google Drive: where diagram exports go, how they are organised, and how other apps read them.

drive_ui <- function(id) {
  ns <- NS(id)
  tok_rows <- data.frame(Token = paste0("<code>{", names(EXPORT_TOKENS), "}</code>"), Means = unname(EXPORT_TOKENS), stringsAsFactors = FALSE)
  tagList(
    topic_hero("☁️", "Google Drive",
      "Every diagram in the app has a ⤓ Save button. Exports land here in a predictable folder hierarchy, with a manifest that other Shiny apps can read.",
      c("Service account or Google sign-in", "Shared drives", "Hierarchical folders created automatically", "manifest.csv / manifest.json", "Folder sync alternative")),
    uiOutput(ns("status")),
    fluidRow(
      box(title = "1 · Default destination and formats", status = "primary", solidHeader = TRUE, width = 6,
        radioButtons(ns("backend"), "Save exports to", c("Google Drive (API)" = "drive", "Folder on this computer — e.g. a Google Drive for desktop folder" = "local", "Download only (no saving)" = "download")),
        checkboxGroupInput(ns("formats"), "Formats ticked by default", EXPORT_FORMATS, inline = TRUE),
        fluidRow(column(6, numericInput(ns("gif_delay"), "GIF frame delay (ms)", 900, min = 150, max = 5000, step = 50)),
                 column(6, numericInput(ns("gif_max"), "GIF max frames", 60, min = 2, max = 120))),
        checkboxInput(ns("manifest"), "Maintain manifest.csv and manifest.json in <app>/_index/", TRUE),
        actionButton(ns("save_general"), "Save", class = "btn btn-dsa")),
      box(title = "2 · Folder hierarchy", status = "primary", solidHeader = TRUE, width = 6,
        textInput(ns("app_folder"), "App folder (top level under the root)", "DSA-Academy"),
        textInput(ns("template"), "Path template", EXPORT_TEMPLATE_DEFAULT, width = "100%"),
        uiOutput(ns("tpl_check")),
        tags$div(class = "code-title", "Example"), uiOutput(ns("tpl_preview")),
        tags$details(class = "iv-details", tags$summary("Available tokens"), cplx_table(tok_rows)),
        tags$div(class = "stepper-btns", style = "margin-top:8px;",
          actionButton(ns("save_tpl"), "Save template", class = "btn btn-dsa"),
          actionButton(ns("reset_tpl"), "Restore default", class = "btn btn-dsa-outline")))
    ),
    fluidRow(
      box(title = "3 · Google Drive API", status = "primary", solidHeader = TRUE, width = 7,
        radioButtons(ns("auth"), "Authenticate with", inline = TRUE,
          c("Service account key (recommended for sharing with other apps)" = "service", "My Google account (OAuth sign-in)" = "oauth")),
        conditionalPanel(sprintf("input['%s'] == 'service'", ns("auth")),
          fileInput(ns("key_upload"), "Upload the service-account JSON key", accept = ".json"),
          textInput(ns("key_path"), "…or path to the key file", "", width = "100%"),
          uiOutput(ns("sa_email"))),
        conditionalPanel(sprintf("input['%s'] == 'oauth'", ns("auth")),
          textInput(ns("oauth_email"), "Google account email (optional, picks a cached token)", ""),
          fileInput(ns("client_upload"), "Optional: your own OAuth client JSON (Desktop app type)", accept = ".json"),
          textInput(ns("client_path"), "…or path to the OAuth client file", "", width = "100%"),
          hint("Sign-in opens a browser window on the machine running R, so start the app from an interactive R session (RStudio or the R console). The token is cached in <code>data/.gargle/</code>.")),
        tags$hr(),
        fluidRow(
          column(6, textInput(ns("root_id"), "Root folder ID (preferred)", "", placeholder = "e.g. 1AbC…xyz from the folder URL")),
          column(6, textInput(ns("root_name"), "…or root folder name (created in My Drive)", "DSA-Academy-Exports"))),
        textInput(ns("shared"), "Shared drive ID (only if the root folder is in a shared drive)", "", width = "100%"),
        tags$div(class = "stepper-btns",
          actionButton(ns("save_drive"), "Save", class = "btn btn-dsa"),
          actionButton(ns("test_drive"), "Connect & test", class = "btn btn-dsa"),
          actionButton(ns("clear_cache"), "Clear folder-ID cache", class = "btn btn-dsa-outline"),
          actionButton(ns("signout"), "Sign out", class = "btn btn-dsa-outline")),
        uiOutput(ns("drive_result"))),
      box(title = "Setting up access", status = "info", solidHeader = TRUE, width = 5,
        tags$div(class = "code-title", "Service account (works unattended; best for several apps)"),
        tags$ol(class = "fu-list",
          tags$li("In Google Cloud Console create a project and enable the Google Drive API."),
          tags$li("IAM & Admin › Service accounts › create one, then Keys › Add key › JSON. Upload that file above."),
          tags$li(HTML("Service accounts have <b>no storage quota of their own</b>: put the root folder in a <b>shared drive</b> and add the service-account email as a Content manager, then enter the folder ID and the shared drive ID.")),
          tags$li("Give your other Shiny apps the same key (read access) to read the files.")),
        tags$div(class = "code-title", "Your Google account"),
        tags$ol(class = "fu-list",
          tags$li("Choose OAuth, press Connect & test, and approve access in the browser window."),
          tags$li("For heavier use, create your own OAuth client (Desktop app) in Cloud Console and upload its JSON — the shared default client is rate-limited.")),
        tags$div(class = "code-title", "No API at all"),
        tags$p(class = "hint", HTML("Install <b>Google Drive for desktop</b>, choose <b>Folder</b> as the destination, and point it at a folder inside the synced drive, e.g. <code>G:/My Drive/DSA</code> on Windows or <code>~/Library/CloudStorage/GoogleDrive-you@gmail.com/My Drive/DSA</code> on macOS. Drive syncs the files for you.")))
    ),
    fluidRow(
      box(title = "4 · Folder destination", status = "primary", solidHeader = TRUE, width = 6,
        textInput(ns("local_root"), "Root folder on this computer", "", width = "100%"),
        tags$div(class = "stepper-btns",
          actionButton(ns("save_local"), "Save", class = "btn btn-dsa"),
          actionButton(ns("test_local"), "Create & test", class = "btn btn-dsa-outline")),
        uiOutput(ns("local_result"))),
      box(title = "5 · Reading the exports from another Shiny app", status = "success", solidHeader = TRUE, width = 6,
        tabsetPanel(
          tabPanel("Google Drive", dsa_code(
'library(googledrive)
drive_auth(path = "service-account.json")      # same key, read access is enough
idx  <- drive_ls(as_id("<ROOT_FOLDER_ID>"), recursive = TRUE, pattern = "^manifest[.]csv$")
tmp  <- tempfile(fileext = ".csv")
drive_download(as_id(idx$id[1]), path = tmp, overwrite = TRUE)
man  <- read.csv(tmp)                            # one row per exported file
pick <- subset(man, topic == "Graphs" & format == "png")
drive_download(as_id(pick$location[1]), path = "latest.png", overwrite = TRUE)
# in the UI:  renderImage(list(src = "latest.png"), deleteFile = FALSE)')),
          tabPanel("Synced folder", dsa_code(
'root <- "G:/My Drive/DSA"                       # the Folder destination above
man  <- read.csv(file.path(root, "DSA-Academy", "_index", "manifest.csv"))
pick <- subset(man, topic == "Graphs" & format == "html")
# location is the full path of the file
shiny::includeHTML(pick$location[1])')),
          tabPanel("Manifest columns", cplx_table(data.frame(
            Column = MANIFEST_COLS,
            Meaning = c("one id per Save click (files of one export share it)", "timestamp", "drive / local", "sidebar group", "page", "tab inside the page",
                        "diagram (box title)", "step i/n for step-through diagrams", "your label", "png, svg, pdf, html, gif, json", "MIME type",
                        "file name", "folders below the root", "folder_path/file_name", "Drive file id or full local path", "web or file link", "size in bytes"),
            stringsAsFactors = FALSE)))))
    ),
    fluidRow(
      box(title = "Export history", status = "primary", solidHeader = TRUE, width = 12,
        uiOutput(ns("hist_kpi")), DTOutput(ns("history")),
        tags$div(class = "stepper-btns", style = "margin-top:8px;", actionButton(ns("rebuild"), "Rebuild manifest from history", class = "btn btn-dsa-outline btn-sm")))
    ),
    ref_block("googledrive R package — https://googledrive.tidyverse.org",
              "gargle authentication guides — https://gargle.r-lib.org/articles/",
              "Google Drive API v3 — https://developers.google.com/drive/api/guides/about-sdk")
  )
}

drive_server <- function(id, progress = NULL, bus) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    rv <- reactiveValues(tick = 0, drive_msg = NULL, local_msg = NULL)
    secrets <- file.path(DATA_DIR, "secrets")

    # load current settings into the form
    isolate({
      s <- export_settings()
      updateRadioButtons(session, "backend", selected = s$export_backend)
      updateCheckboxGroupInput(session, "formats", selected = strsplit(s$export_formats, ",")[[1]])
      updateNumericInput(session, "gif_delay", value = as.numeric(s$gif_delay)); updateNumericInput(session, "gif_max", value = as.numeric(s$gif_max))
      updateCheckboxInput(session, "manifest", value = s$manifest == "1")
      updateTextInput(session, "app_folder", value = s$app_folder); updateTextInput(session, "template", value = s$path_template)
      updateRadioButtons(session, "auth", selected = s$drive_auth)
      updateTextInput(session, "key_path", value = s$drive_key_path); updateTextInput(session, "oauth_email", value = s$drive_oauth_email)
      updateTextInput(session, "client_path", value = s$drive_oauth_client)
      updateTextInput(session, "root_id", value = s$drive_root_id); updateTextInput(session, "root_name", value = s$drive_root_name)
      updateTextInput(session, "shared", value = s$drive_shared_drive); updateTextInput(session, "local_root", value = s$local_root)
    })

    output$status <- renderUI({
      rv$tick; s <- export_settings()
      dest <- switch(s$export_backend, drive = "Google Drive (API)", local = "Folder", download = "Download only")
      conn <- if (s$export_backend == "drive") {
        if (isTRUE(.drv$ok)) sprintf("connected as %s", .drv$who) else if (!drive_available()) "googledrive package not installed" else "not connected yet — press Connect & test"
      } else s$local_root
      kpi_row(kpi(dest, "default destination", COL$pri), kpi(conn, if (s$export_backend == "drive") "Drive status" else "folder", if (s$export_backend == "drive" && !isTRUE(.drv$ok)) COL$warn else COL$ok),
              kpi(nrow(db_exports()), "files exported", COL$acc))
    })

    observeEvent(input$save_general, {
      setting_set("export_backend", input$backend); setting_set("export_formats", paste(input$formats, collapse = ","))
      setting_set("gif_delay", input$gif_delay); setting_set("gif_max", input$gif_max); setting_set("manifest", if (isTRUE(input$manifest)) "1" else "0")
      rv$tick <- rv$tick + 1; showNotification("Saved.", type = "message")
    })

    # template
    output$tpl_check <- renderUI({ e <- validate_template(input$template %||% ""); if (!is.null(e)) callout(e, "warn") })
    output$tpl_preview <- renderUI({
      meta <- list(group = "Trees & Graphs", topic_label = "Graphs", section = "Visualise", title = "Dijkstra — cheapest path with weighted edges", label = "")
      p <- build_export_path(meta, "png", input$template %||% EXPORT_TEMPLATE_DEFAULT, app = clean_folder(input$app_folder %||% "DSA-Academy"))
      tags$pre(class = "exp-path", paste0("<root>/", p$rel))
    })
    observeEvent(input$save_tpl, {
      e <- validate_template(input$template)
      if (!is.null(e)) { showNotification(e, type = "error"); return() }
      setting_set("path_template", input$template); setting_set("app_folder", clean_folder(input$app_folder))
      showNotification("Template saved. New exports use it; existing files are not moved.", type = "message")
    })
    observeEvent(input$reset_tpl, updateTextInput(session, "template", value = EXPORT_TEMPLATE_DEFAULT))

    # secrets uploads
    store_secret <- function(f, name) {
      dir.create(secrets, showWarnings = FALSE, recursive = TRUE)
      dest <- file.path(secrets, name)
      file.copy(f$datapath, dest, overwrite = TRUE)
      try(Sys.chmod(dest, "600"), silent = TRUE)
      normalizePath(dest)
    }
    observeEvent(input$key_upload, {
      f <- input$key_upload
      j <- tryCatch(jsonlite::fromJSON(f$datapath), error = function(e) NULL)
      if (is.null(j) || !identical(j$type, "service_account")) { showNotification("That file is not a service-account key (type must be service_account).", type = "error"); return() }
      updateTextInput(session, "key_path", value = store_secret(f, "drive-service-account.json"))
      showNotification(sprintf("Key stored for %s. Press Save.", j$client_email), type = "message")
    })
    observeEvent(input$client_upload, {
      updateTextInput(session, "client_path", value = store_secret(input$client_upload, "drive-oauth-client.json"))
    })
    output$sa_email <- renderUI({
      p <- input$key_path %||% ""
      if (!nzchar(p) || !file.exists(p)) return(NULL)
      j <- tryCatch(jsonlite::fromJSON(p), error = function(e) NULL)
      if (!is.null(j$client_email)) hint(sprintf("Service account: <code>%s</code> — share your shared drive / folder with this address.", j$client_email))
    })

    save_drive <- function() {
      setting_set("drive_auth", input$auth); setting_set("drive_key_path", input$key_path); setting_set("drive_oauth_email", input$oauth_email)
      setting_set("drive_oauth_client", input$client_path); setting_set("drive_root_id", trimws(input$root_id))
      setting_set("drive_root_name", clean_folder(input$root_name)); setting_set("drive_shared_drive", trimws(input$shared))
      .drv$ok <- FALSE
      rv$tick <- rv$tick + 1
    }
    observeEvent(input$save_drive, { save_drive(); showNotification("Google Drive settings saved.", type = "message") })
    observeEvent(input$test_drive, {
      save_drive()
      s <- export_settings()
      rv$drive_msg <- tryCatch({
        drive_connect(s, force = TRUE)
        root <- drive_root(s)
        folder <- drive_ensure(s, c(clean_folder(s$app_folder), "_index"))
        tmp <- tempfile(fileext = ".txt"); writeLines(sprintf("DSA Academy connection test %s", now_ts()), tmp)
        up <- G("drive_upload")(media = tmp, path = G("as_id")(folder), name = "_connection-test.txt", overwrite = TRUE)
        callout(sprintf("✅ Connected as <b>%s</b>. Root folder <a href='https://drive.google.com/drive/folders/%s' target='_blank'>%s</a>; created <code>%s/_index/_connection-test.txt</code>.",
                        .drv$who, root, root, clean_folder(s$app_folder)), "success")
      }, error = function(e) callout(paste0("<b>Could not connect.</b> ", htmltools::htmlEscape(conditionMessage(e))), "warn"))
      rv$tick <- rv$tick + 1
    })
    output$drive_result <- renderUI(rv$drive_msg)
    observeEvent(input$clear_cache, { drive_cache_clear(); showNotification("Folder-ID cache cleared; folders will be looked up again.", type = "message") })
    observeEvent(input$signout, {
      if (drive_available() && is.null(.drv$mock)) try(googledrive::drive_deauth(), silent = TRUE)
      .drv$ok <- FALSE; rv$tick <- rv$tick + 1; rv$drive_msg <- callout("Signed out.", "info")
    })

    # local folder
    observeEvent(input$save_local, { setting_set("local_root", input$local_root); rv$tick <- rv$tick + 1; showNotification("Folder saved.", type = "message") })
    observeEvent(input$test_local, {
      setting_set("local_root", input$local_root); s <- export_settings()
      rv$local_msg <- tryCatch({
        d <- file.path(s$local_root, clean_folder(s$app_folder), "_index")
        dir.create(d, recursive = TRUE, showWarnings = FALSE)
        writeLines(sprintf("DSA Academy test %s", now_ts()), file.path(d, "_connection-test.txt"))
        callout(sprintf("✅ Writable: <code>%s</code>", htmltools::htmlEscape(normalizePath(d))), "success")
      }, error = function(e) callout(paste("Not writable:", conditionMessage(e)), "warn"))
      rv$tick <- rv$tick + 1
    })
    output$local_result <- renderUI(rv$local_msg)

    # history
    hist <- reactive({ rv$tick; bus$export_tick; db_exports() })
    output$hist_kpi <- renderUI({
      h <- hist()
      if (!nrow(h)) return(hint("Nothing exported yet. Use the ⤓ Save button on any diagram."))
      kpi_row(kpi(length(unique(h$export_id)), "exports", COL$pri), kpi(sum(h$status == "saved"), "files saved", COL$ok),
              kpi(sum(h$status == "failed"), "failed", if (any(h$status == "failed")) COL$err else COL$ok),
              kpi(sprintf("%.1f MB", sum(h$bytes, na.rm = TRUE) / 1e6), "total size", COL$acc))
    })
    output$history <- renderDT({
      h <- hist(); req(nrow(h) > 0)
      d <- data.frame(When = h$ts, Where = h$backend, Topic = h$topic, Diagram = h$diagram, Format = toupper(h$format),
                      Path = h$rel_path,
                      Open = ifelse(nzchar(h$link %||% "") & h$status == "saved", sprintf("<a href='%s' target='_blank'>open</a>", h$link), ""),
                      Status = ifelse(h$status == "saved", "✅", paste("❌", h$error)), stringsAsFactors = FALSE)
      datatable(d, escape = FALSE, rownames = FALSE, selection = "none", options = list(pageLength = 10, dom = "ftip", ordering = FALSE))
    })
    observeEvent(input$rebuild, {
      h <- hist(); h <- h[h$status == "saved", ]
      s <- export_settings()
      for (b in unique(h$backend)) {
        hb <- h[h$backend == b, ]
        rows <- data.frame(export_id = hb$export_id, created = hb$ts, backend = hb$backend, group = hb$group_name, topic = hb$topic,
                           section = hb$section, diagram = hb$diagram, step = hb$step, label = hb$label, format = hb$format,
                           mime = unname(EXPORT_MIME[hb$format]), file_name = hb$file_name, folder_path = hb$folder_path, rel_path = hb$rel_path,
                           location = hb$location, link = hb$link, bytes = as.character(hb$bytes), stringsAsFactors = FALSE)
        err <- tryCatch({ manifest_update(s, b, rows); NULL }, error = function(e) conditionMessage(e))
        showNotification(if (is.null(err)) sprintf("Manifest rebuilt (%s, %d files).", b, nrow(rows)) else paste("Manifest error:", err),
                         type = if (is.null(err)) "message" else "error")
      }
    })
  })
}
