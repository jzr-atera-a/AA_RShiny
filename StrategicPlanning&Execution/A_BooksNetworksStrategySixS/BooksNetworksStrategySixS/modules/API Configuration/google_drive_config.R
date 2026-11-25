# modules/API Configuration/google_drive_config.R
# ---- module --------------------------------------------------------------------------------------
# id:           google_drive_config
# name:         Google Drive Settings
# label:        Google Drive
# icon:         google-drive
# description:  Sign in to Google Drive and choose the folder where every visualisation tab's "Save to Google Drive" files go
# packages:     shiny, shinydashboard, httr, jsonlite, openssl, DT
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

google_drive_config_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = "Google Drive: where saved diagrams go", status = "primary", solidHeader = TRUE, width = 12,
        uiOutput(ns("status")),
        p("Every tab that shows a diagram, table, graph, design, matrix or infographic has a ", tags$strong("Save to Google Drive"),
          " button next to Download. It saves the file in the chosen format (HTML, PDF, PNG, JPEG, GIF, PowerPoint, or a ZIP of slides) ",
          "into one Google Drive folder, in a fixed hierarchy that other R Shiny apps can read. Missing folders are created as files are added."),
        tags$details(open = NA, style = "margin-bottom:10px;",
          tags$summary(style = "cursor:pointer;font-weight:600;", "The folder hierarchy"),
          uiOutput(ns("scheme"))),

        h4("1. How the app signs in to Google Drive"),
        radioButtons(ns("mode"), NULL, inline = TRUE, selected = "service_account",
          choices = c("Service account key (recommended for a Shared Drive)" = "service_account",
                      "Google account (OAuth)" = "oauth", "Off" = "none")),
        conditionalPanel(sprintf("input['%s'] == 'service_account'", ns("mode")),
          div(class = "well",
            p(style = "font-size:12.5px;color:#555;",
              "A service-account JSON key, for example the same key as BigQuery (the Google Drive API must be enabled in that Google Cloud project). ",
              tags$strong("Google gives service accounts no storage of their own:"), " the root folder below must be in a ", tags$strong("Shared Drive"),
              ", with the service account added as a member (Content manager). Uploads into a normal My Drive folder are refused by Google."),
            fluidRow(
              column(8, textInput(ns("sa_path"), "Key file on the computer running the app:", width = "100%",
                                  placeholder = "e.g. C:/111_SecA/_q_api/atera-2-key.json")),
              column(4, br(), actionButton(ns("use_bq_key"), "Use the BigQuery key", icon = icon("database"), style = "width:100%;"))),
            fileInput(ns("sa_upload"), "...or upload the key (kept only in this computer's private settings folder):", accept = ".json"),
            uiOutput(ns("sa_email")))),
        conditionalPanel(sprintf("input['%s'] == 'oauth'", ns("mode")),
          div(class = "well",
            p(style = "font-size:12.5px;color:#555;",
              "Files are stored in your own Google account. Create an OAuth client in Google Cloud Console > APIs & Services > Credentials ",
              "(enable the Google Drive API first). Two ways to get the refresh token:"),
            tags$ul(style = "font-size:12.5px;color:#555;",
              tags$li(tags$strong("Sign in with Google here:"), " client type ", tags$em("TVs and Limited Input devices"), ". Google limits this sign-in to files and ",
                      "folders the app creates itself, so leave the root folder empty (the app creates its folder in your My Drive) or use a folder the app created."),
              tags$li(tags$strong("Paste a refresh token"), " with full Drive access (for example from the OAuth 2.0 Playground, with ", tags$em("Use your own OAuth credentials"),
                      " ticked and the scope https://www.googleapis.com/auth/drive). Any root folder you can edit then works.")),
            fluidRow(
              column(6, textInput(ns("client_id"), "OAuth client ID:", width = "100%", placeholder = "1234567890-abc...apps.googleusercontent.com")),
              column(6, passwordInput(ns("client_secret"), "OAuth client secret:", width = "100%"))),
            passwordInput(ns("refresh_token"), "Refresh token (filled in by Sign in with Google, or paste one):", width = "100%"),
            actionButton(ns("device_start"), "Sign in with Google", icon = icon("google"), class = "btn-info"),
            uiOutput(ns("device_box")))),

        h4("2. Where to save"),
        fluidRow(
          column(7, textInput(ns("root_id"), "Root folder (ID or link of a Drive folder; empty = the app creates its folder in My Drive, Google account only):",
                              width = "100%", placeholder = "https://drive.google.com/drive/folders/1AbC...")),
          column(3, textInput(ns("app_folder"), "App folder name:", value = "BooksNetworksStrategySixS", width = "100%")),
          column(2, br(), checkboxInput(ns("manifest"), "Keep _manifest.csv", value = TRUE))),

        fluidRow(
          column(3, actionButton(ns("apply_test"), "Apply and Test", icon = icon("plug"), class = "btn-info", style = "width:100%;")),
          column(3, actionButton(ns("save"), "Save Settings on this Computer", icon = icon("save"), class = "btn-success", style = "width:100%;")),
          column(3, actionButton(ns("reload"), "Load from Key Folder", icon = icon("folder-open"), style = "width:100%;")),
          column(3, actionButton(ns("forget"), "Forget Saved Settings", icon = icon("trash"), class = "btn-danger", style = "width:100%;"))),
        p(style = "font-size:12px;color:#7f8c8d;margin-top:8px;",
          "At start-up the app reads ", tags$code("google_drive.json"), " from the key folder (Windows: C:/111_SecA/_q_api, or the folder in LAT_CRED_DIR), ",
          "then the settings saved on this computer. Example key-folder file:"),
        tags$div(class = "gd-code", paste(
          '{',
          '  "mode": "service_account",',
          '  "service_account_key": "atera-2-key.json",',
          '  "root_folder_id": "<ID of a folder in a Shared Drive>",',
          '  "app_folder": "BooksNetworksStrategySixS",',
          '  "manifest": true',
          '}',
          '(Google account instead: "mode": "oauth", "client_id", "client_secret", "refresh_token")', sep = "\n")),
        htmlOutput(ns("result"))
      )
    ),
    fluidRow(
      box(title = "Saved files", status = "success", solidHeader = TRUE, width = 12, collapsible = TRUE,
        uiOutput(ns("folder_link")),
        actionButton(ns("load_manifest"), "Show the Manifest", icon = icon("list"), class = "btn-default"),
        br(), br(),
        DT::dataTableOutput(ns("manifest_table")),
        uiOutput(ns("recent")))
    ),
    fluidRow(
      box(title = "Reading the saved files from another R Shiny app", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE,
        p("Use the manifest (one row per file, with the file id, folder path and metadata) or search by the metadata every file carries. ",
          "Example with the googledrive package:"),
        tags$div(class = "gd-code", paste(
          'library(googledrive)',
          'drive_auth(path = "service-account-key.json")   # or drive_auth(email = "you@example.com")',
          '',
          'app <- as_id("<ID of the app folder: see Saved files above>")',
          'man <- drive_ls(app, pattern = "^_manifest\\\\.csv$")',
          'tmp <- drive_download(man, path = tempfile(fileext = ".csv"))',
          'idx <- read.csv(tmp$local_path, colClasses = "character")',
          '',
          '# e.g. the latest PDF of each strategy diagram',
          'pdf <- subset(idx, main_group == "Strategic Analysis" & format == "pdf")',
          'pdf <- pdf[order(pdf$saved_at, decreasing = TRUE), ]',
          'drive_download(as_id(pdf$file_id[1]), path = "diagram.pdf", overwrite = TRUE)',
          '',
          '# or search Drive directly by metadata',
          'drive_find(q = "appProperties has { key=\'group\' and value=\'Mind Map\' }")', sep = "\n")),
        p(style = "font-size:12px;color:#7f8c8d;margin-top:8px;", "Manifest columns: ", paste(GD_MANIFEST_COLS, collapse = ", "), "."))
    )
  )
}

# ==== Server =======================================================================================

google_drive_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    tick <- reactiveVal(0)
    bump <- function() tick(tick() + 1)
    device <- reactiveVal(NULL)

    fill_inputs <- function() {
      c0 <- gd_cfg()
      updateRadioButtons(session, "mode", selected = if (identical(c0$mode, "none") && !gd_configured()) "service_account" else c0$mode)
      updateTextInput(session, "sa_path", value = c0$sa_path)
      updateTextInput(session, "client_id", value = c0$client_id)
      updateTextInput(session, "client_secret", value = c0$client_secret)
      updateTextInput(session, "refresh_token", value = c0$refresh_token)
      updateTextInput(session, "root_id", value = c0$root_id)
      updateTextInput(session, "app_folder", value = c0$app_folder)
      updateCheckboxInput(session, "manifest", value = isTRUE(c0$manifest))
    }
    # settings auto-loaded at start-up arrive a moment after the page: copy them into the boxes once they do
    filled <- reactiveVal(FALSE)
    observe({
      if (filled()) return()
      invalidateLater(1500)
      if (gd_configured()) { fill_inputs(); filled(TRUE) }
    })

    apply_inputs <- function() {
      mode <- input$mode %||% "none"
      gd_configure(mode, sa_path = input$sa_path %||% "", client_id = input$client_id %||% "", client_secret = input$client_secret %||% "",
                   refresh_token = input$refresh_token %||% "", root_id = input$root_id %||% "", app_folder = input$app_folder %||% "",
                   manifest = isTRUE(input$manifest),
                   oauth_scope = if (identical(mode, "oauth") && identical(gd_cfg()$oauth_scope, GD_SCOPE_FILE)) GD_SCOPE_FILE else GD_SCOPE_FULL)
    }
    show_result <- function(cls, ...) output$result <- renderUI(tags$div(class = cls, style = "margin-top:10px;", ...))

    output$status <- renderUI({
      invalidateLater(2500); tick()
      st <- gd_status(); c0 <- gd_cfg()
      col <- switch(st$state, ok = c("#ecfdf5", "#a7f3d0", "#065f46"), warn = c("#fffbeb", "#fde68a", "#92400e"), pending = c("#fffbeb", "#fde68a", "#92400e"),
                    error = c("#fef2f2", "#fecaca", "#991b1b"), c("#f1f5f9", "#cbd5e1", "#334155"))
      tags$div(style = sprintf("background:%s;border:1px solid %s;color:%s;border-radius:8px;padding:8px 10px;margin-bottom:10px;font-size:12.5px;", col[1], col[2], col[3]),
        icon("google-drive"), " ", tags$strong(switch(st$state, ok = "Ready. ", warn = "Connected, with a warning. ", pending = "Not tested yet. ", error = "Problem. ", "Not set up. ")),
        st$msg, if (nzchar(c0$source %||% "")) tags$span(style = "opacity:.75;", sprintf(" (settings from %s)", c0$source)))
    })

    output$scheme <- renderUI({
      app <- gd_safe_name(input$app_folder %||% "", empty = "BooksNetworksStrategySixS")
      tags$div(class = "gd-scheme", paste(
        "<root folder>/",
        sprintf("  %s/", app),
        "    _README.txt             what the hierarchy and the manifest mean",
        "    _manifest.csv           one row per saved file (path, file id, link, metadata)",
        "    <Main group>/           Book Summary, Flex Table, Mind Map, Knowledge Graph, Sankey Graph,",
        "                            Strategic Analysis, Six Sigma Analysis, Technical Designs",
        "      <Category>/           the diagram's category (Technical Designs: the design group)",
        "        <Domain>/           its domain (Book Summary: the author)",
        "          <Topic>/          its topic          ('_General' when a level is not set)",
        "            <Title>/",
        "              <Title>__<Sub-tab>__<YYYYMMDD-HHMMSS>.<html|pdf|png|jpg|gif|pptx|zip>",
        "",
        "Example: BooksNetworksStrategySixS/Strategic Analysis/Business/Semiconductors/Intel 1985/Exit memories/",
        "         Exit memories__Browse and Visualise - Visualisations__20261121-101500.pdf", sep = "\n"))
    })

    output$sa_email <- renderUI({
      tick(); p <- trimws(input$sa_path %||% "")
      if (!nzchar(p) || !file.exists(p)) return(if (nzchar(p)) tags$div(class = "status-warning", "This file was not found on the computer running the app.") else NULL)
      j <- tryCatch(jsonlite::fromJSON(p), error = function(e) NULL)
      if (is.null(j$client_email)) return(tags$div(class = "status-warning", "This is not a service-account key."))
      tags$div(class = "status-info", "Service account: ", tags$code(j$client_email),
               ". Add this address as a member of the Shared Drive (or share the root folder with it) with edit rights.")
    })

    observeEvent(input$use_bq_key, {
      k <- api_manager$bq_key_path %||% ""
      if (!nzchar(k)) { lc <- tryCatch(app_local_credentials(), error = function(e) list(json_path = NA)); if (!is.na(lc$json_path)) k <- lc$json_path }
      if (!nzchar(k)) k <- Sys.getenv("ATERA_BQ_KEY_FILE", Sys.getenv("GOOGLE_APPLICATION_CREDENTIALS", ""))
      if (!nzchar(k)) { showNotification("No BigQuery key is known yet: connect BigQuery first, or type the key file.", type = "warning"); return() }
      updateTextInput(session, "sa_path", value = k); bump()
    })

    observeEvent(input$sa_upload, {
      f <- input$sa_upload
      j <- tryCatch(jsonlite::fromJSON(f$datapath), error = function(e) NULL)
      if (!identical(j$type, "service_account")) { showNotification("That file is not a service-account key.", type = "error"); return() }
      dest <- file.path(dirname(gd_private_path()), "google_drive_service_account.json")
      dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
      file.copy(f$datapath, dest, overwrite = TRUE); try(Sys.chmod(dest, "600"), silent = TRUE); unlink(f$datapath)
      updateTextInput(session, "sa_path", value = dest); bump()
      showNotification("Key stored in this computer's private settings folder.", type = "message")
    })

    observeEvent(input$apply_test, {
      show_result("status-info", icon("spinner", class = "fa-spin"), " Signing in and checking the folder ...")
      res <- tryCatch({ apply_inputs(); gd_test() }, error = function(e) e)
      bump()
      if (inherits(res, "error")) show_result("status-error", icon("times-circle"), " ", conditionMessage(res))
      else show_result(if (identical(gd_status()$state, "warn")) "status-warning" else "status-success", icon("check-circle"), " ", res,
                       " Click 'Save Settings on this Computer' to keep them for the next start.")
    })

    observeEvent(input$save, {
      res <- tryCatch({ apply_inputs(); gd_save_private() }, error = function(e) e)
      bump()
      if (inherits(res, "error")) show_result("status-error", icon("times-circle"), " ", conditionMessage(res))
      else show_result("status-success", icon("check-circle"), " Saved to ", tags$code(res), " (readable only by your user account). ",
                       "They are loaded automatically next time, unless the key folder has a google_drive.json.")
    })

    observeEvent(input$reload, {
      ok <- tryCatch(gd_autoload(api_manager), error = function(e) FALSE)
      fill_inputs(); bump()
      if (isTRUE(ok)) show_result("status-success", icon("check-circle"), " Loaded: ", gd_status()$msg)
      else show_result("status-warning", icon("exclamation-triangle"), " No google_drive.json in ", if (nzchar(app_cred_dir())) app_cred_dir() else "(no key folder on this system)",
                       " and no saved settings on this computer.")
    })

    observeEvent(input$forget, {
      p <- gd_private_path(); had <- file.exists(p); if (had) unlink(p)
      show_result("status-info", icon("info-circle"), if (had) paste(" Deleted", p) else " Nothing was saved on this computer.",
                  ". The current session keeps its settings until the app restarts.")
    })

    # ---- device-code sign-in --------------------------------------------------------------------------------
    observeEvent(input$device_start, {
      cid <- trimws(input$client_id %||% ""); sec <- trimws(input$client_secret %||% "")
      if (!nzchar(cid) || !nzchar(sec)) { showNotification("Enter the OAuth client ID and secret first.", type = "warning"); return() }
      d <- tryCatch(gd_device_start(cid), error = function(e) e)
      if (inherits(d, "error")) { show_result("status-error", icon("times-circle"), " ", conditionMessage(d)); return() }
      d$client_id <- cid; d$client_secret <- sec
      device(d)
    })
    output$device_box <- renderUI({
      d <- device(); if (is.null(d)) return(NULL)
      url <- d$verification_url %||% d$verification_uri %||% "https://www.google.com/device"
      tags$div(class = "status-info", style = "margin-top:10px;",
        "On any device, open ", tags$a(href = url, target = "_blank", rel = "noopener", url), " and enter this code:",
        tags$div(class = "gd-devcode", d$user_code),
        tags$small("Waiting for your approval ... (the code expires in ", round((d$expires_in %||% 1800) / 60), " minutes)"))
    })
    observe({
      d <- device(); if (is.null(d)) return()
      invalidateLater(max(5, as.numeric(d$interval %||% 5)) * 1000)
      if (as.numeric(Sys.time()) - d$started > as.numeric(d$expires_in %||% 1800)) { device(NULL); show_result("status-warning", " The sign-in code expired: try again."); return() }
      r <- tryCatch(gd_device_poll(d$client_id, d$client_secret, d$device_code), error = function(e) list(status = "error", msg = conditionMessage(e)))
      if (identical(r$status, "pending")) { if (isTRUE(r$slow)) { d$interval <- as.numeric(d$interval %||% 5) + 5; device(d) }; return() }
      device(NULL)
      if (identical(r$status, "ok")) {
        updateTextInput(session, "refresh_token", value = r$token$refresh_token)
        res <- tryCatch({
          isolate(gd_configure("oauth", client_id = d$client_id, client_secret = d$client_secret, refresh_token = r$token$refresh_token,
                       root_id = input$root_id %||% "", app_folder = input$app_folder %||% "", manifest = isTRUE(input$manifest),
                       oauth_scope = GD_SCOPE_FILE))
          gd_test() }, error = function(e) e)
        bump()
        if (inherits(res, "error")) show_result("status-error", icon("times-circle"), " Signed in, but: ", conditionMessage(res))
        else show_result("status-success", icon("check-circle"), " Signed in with Google. ", res, " Click 'Save Settings on this Computer' to keep the sign-in.")
      } else show_result("status-error", icon("times-circle"), " Sign-in not completed: ", r$msg %||% "")
    })

    # ---- saved files ----------------------------------------------------------------------------------------
    output$folder_link <- renderUI({
      invalidateLater(4000); tick()
      l <- gd_app_folder_link()
      if (!nzchar(l)) return(p(style = "color:#7f8c8d;", "The app folder link appears here after a successful test or the first save."))
      p(icon("folder-open"), " App folder: ", tags$a(href = l, target = "_blank", rel = "noopener", l), " (ID ", tags$code(sub(".*/", "", l)), ")")
    })
    observeEvent(input$load_manifest, {
      df <- tryCatch(gd_manifest_read(), error = function(e) e)
      if (inherits(df, "error")) { showNotification(conditionMessage(df), type = "error", duration = 12); return() }
      if (!nrow(df)) { showNotification("No manifest yet: nothing has been saved to this folder.", type = "message"); return() }
      df <- df[order(df$saved_at, decreasing = TRUE), , drop = FALSE]
      df$web_link <- ifelse(nzchar(df$web_link), sprintf('<a href="%s" target="_blank" rel="noopener">open</a>', htmltools::htmlEscape(df$web_link)), "")
      output$manifest_table <- DT::renderDataTable(DT::datatable(
        df[, c("saved_at", "main_group", "category", "domain", "topic", "title", "format", "sub_tab", "file_name", "web_link")],
        escape = setdiff(seq_len(10), 10), rownames = FALSE, filter = "top", options = list(pageLength = 10, scrollX = TRUE)))
    })
    output$recent <- renderUI({
      invalidateLater(4000)
      r <- .gd$recent
      if (!length(r)) return(NULL)
      tagList(h5("Saved in this session"), tags$ul(lapply(r, function(x) tags$li(x$at, ": ", x$path, " ",
        if (nzchar(x$link %||% "")) tags$a(href = x$link, target = "_blank", rel = "noopener", "open")))))
    })
  })
}
