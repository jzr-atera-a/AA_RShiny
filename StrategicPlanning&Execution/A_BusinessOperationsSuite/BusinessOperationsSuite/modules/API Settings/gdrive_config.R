# modules/API Settings/gdrive_config.R
# Subtab: Google Drive - the account and the folder that every "Save to Google Drive" button uses.
# Settings live in <keys folder>/bos_config.json under "google_drive" (shared with the Android app).

gdrive_config_ui <- function(id) {
  ns <- NS(id)
  s <- tryCatch(gd_load_settings(), error = function(e) gd_settings_default())
  cs <- tryCatch(collab_load_settings(), error = function(e) collab_settings_default())
  fmts <- setdiff(names(DIAGRAM_FORMATS), c("csv", "source"))
  tagList(
    fluidRow(
      box(title = "Google Drive Sign-in", status = "primary", solidHeader = TRUE, width = 6,
        radioButtons(ns("auth_mode"), "Sign in with", inline = FALSE, selected = s$auth_mode,
                     choices = c("Google account (My Drive or a folder the app created)" = "oauth", "Service account (Shared Drive)" = "service_account")),
        conditionalPanel(sprintf("input['%s'] == 'oauth'", ns("auth_mode")),
          textInput(ns("client_id"), "OAuth Client ID", value = s$client_id, placeholder = "1234-abc.apps.googleusercontent.com", width = "100%"),
          passwordInput(ns("client_secret"), "OAuth Client Secret", value = s$client_secret, width = "100%"),
          actionButton(ns("sign_in"), "Sign in with Google", icon = icon("sign-in-alt"), class = "btn-primary"),
          actionButton(ns("sign_out"), "Sign out", icon = icon("sign-out-alt")),
          uiOutput(ns("sign_in_box")),
          tags$details(tags$summary("Advanced: paste a refresh token"),
            tags$p(class = "help-block", "Use this when the token was made elsewhere, e.g. with the full 'drive' scope (which also lets the app write into folders it did not create)."),
            passwordInput(ns("refresh_token"), "Refresh token", value = s$refresh_token, width = "100%")),
          tags$details(tags$summary("How to get a Client ID"),
            tags$ol(
              tags$li("Google Cloud Console > APIs & Services > Library: enable 'Google Drive API'."),
              tags$li("OAuth consent screen: fill it in; while it is in 'Testing', add your Google account under Test users."),
              tags$li("Credentials > Create credentials > OAuth client ID > type 'TVs and Limited Input devices'."),
              tags$li("Copy the Client ID and secret here, press 'Sign in with Google' and enter the code shown on google.com/device.")),
            tags$p(class = "help-block", "This sign-in only lets the app manage the files and folders it creates (scope drive.file), so leave 'Root folder' empty ",
                   "(the app folder is made in My Drive) or use a folder the app made. To write into an existing folder, paste a refresh token with the full ",
                   "drive scope, or use a service account with a Shared Drive."))),
        conditionalPanel(sprintf("input['%s'] == 'service_account'", ns("auth_mode")),
          textInput(ns("key_file"), "Service-account JSON key (optional)", value = s$key_file, placeholder = "empty = the BigQuery key in the keys folder", width = "100%"),
          uiOutput(ns("sa_hint")),
          textInput(ns("impersonate"), "Act as user (optional)", value = s$impersonate, placeholder = "name@company.com - Workspace domain-wide delegation only", width = "100%"),
          tags$p(class = "help-block", "A service account has no Drive storage of its own. Put the root folder inside a Shared Drive and add the service account ",
                 "(its client_email) to that Shared Drive as Content manager - or use domain-wide delegation with 'Act as user'. ",
                 "Enable the Google Drive API in the key's Cloud project.")),
        uiOutput(ns("account_status"))),
      box(title = "Where Files Go", status = "info", solidHeader = TRUE, width = 6,
        textInput(ns("root_folder"), "Root folder (id or link)", value = s$root_folder, placeholder = "empty = My Drive", width = "100%"),
        textInput(ns("app_folder"), "App folder name", value = s$app_folder, width = "100%"),
        checkboxInput(ns("by_date"), "Year and month sub-folders (…/<Tab>/2026/2026-11/)", value = isTRUE(s$by_date)),
        checkboxInput(ns("by_format"), "One sub-folder per format (…/html/, …/pdf/, …/png/)", value = isTRUE(s$by_format)),
        checkboxInput(ns("manifest"), "Keep _manifest.csv up to date (one row per file, for other apps to read)", value = isTRUE(s$manifest)),
        textInput(ns("device_note"), "Computer note (optional, written in the manifest)", value = s$device_note, placeholder = "e.g. Office PC 2", width = "100%"),
        checkboxGroupInput(ns("default_formats"), "Formats ticked by default", inline = TRUE, choices = setNames(fmts, DIAGRAM_FORMATS[fmts]), selected = intersect(s$default_formats, fmts)),
        tags$strong("Example path"),
        tags$div(class = "bos-gd-example", verbatimTextOutput(ns("example"))),
        tags$p(class = "help-block", "Group / Section / Tab follow the sidebar. Every missing folder is created on the first save and existing ones are reused. ",
               "Files are never overwritten (the time is in the name). A _README.txt in the app folder explains the layout."))
    ),
    fluidRow(
      box(title = "Connection", status = "success", solidHeader = TRUE, width = 12,
        actionButton(ns("save"), "Save settings", icon = icon("save"), class = "btn-success"),
        actionButton(ns("test"), "Test connection", icon = icon("plug"), class = "btn-info"),
        actionButton(ns("test_upload"), "Test upload", icon = icon("upload")),
        uiOutput(ns("status")),
        tableOutput(ns("info")),
        tags$hr(),
        tags$strong("Uploaded this session"),
        uiOutput(ns("uploads")))
    ),
    fluidRow(
      box(title = "CollaborationPlanning Folder (shared programmes)", status = "warning", solidHeader = TRUE, width = 12,
        p("The Drive folder of the CollaborationPlanning app (its Admin > Google Drive). Funding Programmes > Collaboration Sync reads its ",
          "analyses and programme backups from there and writes our programmes there as analyses it can read."),
        fluidRow(
          column(4, radioButtons(ns("cp_mode"), "Reach the folder with", selected = cs$mode,
                                 choices = c("Off" = "off", "Google Drive API (service account, Shared Drive)" = "api",
                                             "A folder on this computer (Google Drive for desktop)" = "folder"))),
          column(8,
            conditionalPanel(sprintf("input['%s'] == 'api'", ns("cp_mode")),
              textInput(ns("cp_folder_id"), "Its folder id or link (CP_DRIVE_FOLDER_ID in that app)", value = cs$folder_id, width = "100%"),
              textInput(ns("cp_key_file"), "Service-account JSON key (optional)", value = cs$key_file, width = "100%",
                        placeholder = "empty = the key in the keys folder; use the same key as CollaborationPlanning, or one that is a member of its Shared Drive")),
            conditionalPanel(sprintf("input['%s'] == 'folder'", ns("cp_mode")),
              textInput(ns("cp_local_path"), "The synced folder on this computer", value = cs$local_path, width = "100%",
                        placeholder = "e.g. G:/Shared drives/Team/Collaboration Planning (the same folder as CP_DRIVE_LOCAL_PATH there)")),
            fluidRow(
              column(6, textInput(ns("cp_share_with"), "Who there can see shared programmes", value = cs$share_with, width = "100%",
                                  placeholder = "empty = its owner and admins; 'everyone'; or emails separated by commas")),
              column(6, textInput(ns("cp_exported_by"), "Shared by (an email of yours in that app)", value = cs$exported_by, width = "100%"))))),
        tags$hr(),
        tags$strong("Its tables (read and write)"),
        p(class = "help-block", "CollaborationPlanning keeps its data in BigQuery tables named ", tags$code("cp_..."),
          " in the same project as BigQuery here, and also in a Google Sheet when it has one (it then reads from the Sheet). ",
          "Give the same values as in that app, so what this app writes shows up there straight away."),
        fluidRow(
          column(6, textInput(ns("cp_sheet_id"), "Its Google Sheet id or link (GOOGLE_SHEETS_ID there; empty = no Sheet)", value = cs$sheet_id, width = "100%")),
          column(3, textInput(ns("cp_bq_dataset"), "Dataset (CP_BQ_DATASET)", value = cs$bq_dataset, width = "100%")),
          column(3, textInput(ns("cp_bq_prefix"), "Table prefix (CP_BQ_PREFIX)", value = cs$bq_prefix, width = "100%"))),
        p(class = "help-block", "The Sheet is reached with the service-account key above (or the keys-folder key): share the Sheet with that ",
          "service account as Editor, as CollaborationPlanning's own key is."),
        actionButton(ns("cp_save"), "Save", icon = icon("save"), class = "btn-success"),
        actionButton(ns("cp_test"), "Test folder", icon = icon("plug"), class = "btn-info"),
        actionButton(ns("cp_test_tables"), "Test its tables", icon = icon("table"), class = "btn-info"),
        uiOutput(ns("cp_status")))
    )
  )
}

gdrive_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    device <- reactiveVal(NULL)     # running device sign-in
    tick <- reactiveVal(0)          # bumps when the saved settings change
    status <- function(cls, ...) output$status <- renderUI(tags$div(class = paste("bos-ds-status", cls), paste0(...)))

    current <- function() {
      s <- gd_load_settings()
      s$auth_mode <- input$auth_mode %|g|% s$auth_mode
      for (k in c("client_id", "client_secret", "refresh_token", "key_file", "impersonate", "root_folder", "app_folder", "device_note")) s[[k]] <- trimws(input[[k]] %|g|% "")
      for (k in c("by_date", "by_format", "manifest")) s[[k]] <- isTRUE(input[[k]])
      s$default_formats <- input$default_formats %|g|% character(0)
      s
    }
    save_now <- function(s = current()) {
      p <- gd_save_settings(s)
      session$userData$gdrive <- NULL
      tick(tick() + 1)
      p
    }

    output$example <- renderText({
      s <- gd_settings_default(); s$app_folder <- input$app_folder %|g|% ""; s$by_date <- isTRUE(input$by_date); s$by_format <- isTRUE(input$by_format)
      p <- diagram_placement("analytics", "Word Count Distribution")   # real Group / Section / Tab names
      paste0(if (nzchar(trimws(input$root_folder %|g|% ""))) "<root folder>" else "My Drive", "/", paste(gd_folders(p, s, "html"), collapse = "/"), "/", gd_file_name(p, "html"))
    })

    output$sa_hint <- renderUI({
      jp <- tryCatch(cred_local()$json_path, error = function(e) NA)
      tags$p(class = "help-block", if (nzchar(input$key_file %|g|% "")) "Using the key file above."
             else if (!is.na(jp)) sprintf("Empty = the keys-folder key %s.", basename(jp)) else "Empty = the keys-folder key (none found).")
    })

    output$account_status <- renderUI({
      tick()
      s <- gd_load_settings()
      ok <- gd_configured(s, tryCatch(cred_local()$json_path, error = function(e) NA))
      tags$div(class = paste("bos-ds-status", if (ok) "bos-ds-ok" else "bos-ds-busy"),
               if (!ok) "Not set up yet." else if (s$auth_mode == "oauth") paste0("Signed in", if (nzchar(s$account_email)) paste0(" as ", s$account_email) else "", ".")
               else "Service account set.", sprintf("  Settings file: %s", gd_config_path()))
    })

    observeEvent(input$save, { p <- save_now(); status("bos-ds-ok", "✓ Settings saved to ", p) })

    # ---- device sign-in: show the code, then poll every few seconds without blocking the app
    observeEvent(input$sign_in, {
      s <- current()
      if (!nzchar(s$client_id)) return(status("bos-ds-err", "Enter the OAuth Client ID (and secret) first - see 'How to get a Client ID'."))
      d <- tryCatch(gd_device_start(s$client_id), error = function(e) e)
      if (inherits(d, "error")) return(status("bos-ds-err", conditionMessage(d)))
      d$client_id <- s$client_id; d$client_secret <- s$client_secret
      device(d)
      status("bos-ds-busy", "Waiting for you to approve the sign-in in the browser...")
    })
    output$sign_in_box <- renderUI({
      d <- device(); if (is.null(d)) return(NULL)
      tags$div(style = "margin-top:10px;padding:12px;border-radius:8px;background:rgba(0,138,130,0.12);text-align:center",
        tags$div("Open ", tags$a(href = d$verification_url, target = "_blank", d$verification_url), " and enter this code:"),
        tags$div(style = "font-size:28px;font-weight:bold;letter-spacing:3px;margin:6px 0", d$user_code),
        actionButton(ns("cancel_sign_in"), "Cancel", icon = icon("times")))
    })
    observeEvent(input$cancel_sign_in, { device(NULL); status("bos-ds-err", "Sign-in cancelled.") })
    observe({
      d <- device(); req(d)
      invalidateLater(d$interval * 1000)
      r <- tryCatch(isolate(gd_device_poll(d, d$client_id, d$client_secret)), error = function(e) e)
      if (inherits(r, "error")) { device(NULL); return(status("bos-ds-err", conditionMessage(r))) }
      if (identical(r$state, "slow_down")) { d$interval <- d$interval + 5; device(d); return() }
      if (identical(r$state, "ok")) {
        s <- isolate(current()); s$refresh_token <- r$refresh_token; s$account_email <- r$email
        updateTextInput(session, "refresh_token", value = r$refresh_token)
        p <- save_now(s); device(NULL)
        status("bos-ds-ok", sprintf("✓ Signed in%s. Settings saved to %s. Press 'Test connection' to check the folder.", if (nzchar(r$email)) paste0(" as ", r$email) else "", p))
      }
    })
    observeEvent(input$sign_out, {
      s <- current(); s$refresh_token <- ""; s$account_email <- ""
      updateTextInput(session, "refresh_token", value = "")
      save_now(s); status("bos-ds-ok", "Signed out of Google Drive on this computer.")
    })

    # ---- tests
    observeEvent(input$test, {
      save_now()
      output$info <- renderTable(NULL)
      res <- tryCatch({
        g <- gd_session_client(session)
        a <- g$about()
        root <- g$resolve_root()
        root_name <- if (root == "root") "My Drive" else g$file_info(root, fields = "name")$name
        app_id <- g$app_folder()
        if (g$settings$auth_mode == "oauth" && nzchar(a$user$emailAddress %|g|% "")) { s <- gd_load_settings(); s$account_email <- a$user$emailAddress; gd_save_settings(s); tick(tick() + 1) }
        gb <- function(x) sprintf("%.1f GB", as.numeric(x) / 1024^3)
        q <- a$storageQuota
        data.frame(Item = c("Account", "Root folder", "App folder", "Storage"),
                   Value = c(trimws(paste(a$user$displayName %|g|% "", a$user$emailAddress %|g|% "")), root_name,
                             if (nzchar(g$settings$app_folder)) sprintf("%s (id %s)", g$settings$app_folder, app_id) else "(files go straight into the root folder)",
                             if (is.null(q$limit)) if (is.null(q$usage)) "unknown" else paste(gb(q$usage), "used") else paste(gb(q$usage %|g|% 0), "of", gb(q$limit), "used")))
      }, error = function(e) e)
      if (inherits(res, "error")) return(status("bos-ds-err", conditionMessage(res)))
      output$info <- renderTable(res)
      status("bos-ds-ok", "✓ Connected. The app folder and its _README.txt are in place; diagrams can be saved.")
    })
    observeEvent(input$test_upload, {
      save_now()
      res <- tryCatch({
        g <- gd_session_client(session)
        f <- g$save(gd_placement("API Settings", "API Settings", "Google Drive", "gdrive_config", "connection test"), "txt",
                    charToRaw("Business Operations Suite - test file, safe to delete.\n"))
        g$delete(f$id); f
      }, error = function(e) e)
      if (inherits(res, "error")) return(status("bos-ds-err", conditionMessage(res)))
      status("bos-ds-ok", sprintf("✓ Upload works: wrote and removed %s/%s.\n(The empty test folders stay; you can delete them on Drive.)", res$path, res$name))
    })

    # ---- CollaborationPlanning folder
    cp_current <- function() {
      cs <- collab_load_settings(); cs$mode <- input$cp_mode %|g|% "off"
      for (k in c("folder_id", "key_file", "local_path", "share_with", "exported_by", "sheet_id", "bq_dataset", "bq_prefix"))
        cs[[k]] <- trimws(input[[paste0("cp_", k)]] %|g|% "")
      cs$sheet_id <- cp_sheet_id(cs$sheet_id)
      if (!nzchar(cs$bq_dataset)) cs$bq_dataset <- "business_strategy"
      cs
    }
    cp_note <- function(cls, ...) output$cp_status <- renderUI(tags$div(class = paste("bos-ds-status", cls), paste0(...)))
    observeEvent(input$cp_save, { p <- collab_save_settings(cp_current()); cp_note("bos-ds-ok", "✓ Saved to ", p) })
    observeEvent(input$cp_test, {
      cs <- cp_current(); collab_save_settings(cs)
      sa <- tryCatch(cred_local()$json_path, error = function(e) NA)
      if (!collab_ready(cs, sa)) return(cp_note("bos-ds-err", if (cs$mode == "off") "Choose how to reach the folder first." else
        if (cs$mode == "api") "Give the folder id/link, and a service-account key (or put one in the keys folder)." else "Give the folder path."))
      r <- tryCatch({ f <- collab_folder(cs, sa); b <- f$latest_backup("programmes")
        list(where = f$where, n = length(f$analyses()), day = if (is.null(b)) "none yet" else b$day) }, error = function(e) e)
      if (inherits(r, "error")) return(cp_note("bos-ds-err", conditionMessage(r)))
      cp_note("bos-ds-ok", sprintf("✓ Folder reachable: %s\nAnalysis files: %d. Latest programmes backup: %s.", r$where, r$n, r$day))
    })

    observeEvent(input$cp_test_tables, {
      cs <- cp_current(); collab_save_settings(cs)
      r <- tryCatch({ st <- cp_connect(api_manager, cs); n <- nrow(cp_read("programmes")); c(st, programmes = n) }, error = function(e) e)
      if (inherits(r, "error")) return(cp_note("bos-ds-err", conditionMessage(r)))
      cp_note("bos-ds-ok", sprintf("✓ Its tables are reachable. Writing to: %s. Reading from: %s.
Programmes there: %d.",
                                   paste(r$write_to, collapse = " + "), r$read_from, r$programmes))
    })

    output$uploads <- renderUI({
      u <- gd_session_uploads(session)()
      if (!nrow(u)) return(tags$p(class = "help-block", "Nothing uploaded yet. Use 'Save to Google Drive' under any diagram."))
      u <- u[rev(seq_len(nrow(u))), , drop = FALSE]
      tags$table(class = "table table-condensed", tags$tr(tags$th("Time"), tags$th("Tab"), tags$th("File"), tags$th("Folder")),
        lapply(seq_len(min(30, nrow(u))), function(i) tags$tr(tags$td(u$time[i]), tags$td(u$tab[i]),
          tags$td(if (nzchar(u$link[i])) tags$a(href = u$link[i], target = "_blank", u$file[i]) else u$file[i]), tags$td(u$folder[i]))))
    })
  })
}
