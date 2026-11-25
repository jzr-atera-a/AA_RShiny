# ---- module ----------------------------------------------
# id:           admin_drive
# name:         Google Drive
# icon:         cloud
# description:  Where copies of the analysis tables are saved: a Shared Drive folder (Drive API) or a synced folder on this computer
# packages:     shiny
# -----------------------------------------------------------

admin_drive_ui <- function(id) {
  ns <- NS(id)
  tagList(
    note("info", tags$b("Drive API"), " works on shinyapps.io: make a folder inside a ", tags$b("Shared Drive"),
         ", add the service account (shown below) as Content manager, and paste the folder's ID (the last part of its web address). ",
         tags$b("Synced folder"), " works when the app runs on your own computer: point it at a Google Drive for desktop folder, ",
         "for example G:/My Drive/Collaboration Planning."),
    card("Where to save",
      radioButtons(ns("mode"), NULL, c("Off" = "off", "Drive API (Shared Drive folder)" = "api", "Synced folder on this computer" = "folder"), inline = TRUE),
      uiOutput(ns("sa")),
      textInput(ns("folder_id"), "Drive folder ID", width = "100%", placeholder = "e.g. 1AbCdEfGhIjKlMnOpQrStUvWxYz"),
      textInput(ns("path"), "Folder path", width = "100%", placeholder = "G:/My Drive/Collaboration Planning"),
      checkboxInput(ns("auto"), "Copy every table to Drive once a day (Backups/<date>/), when the owner signs in", TRUE),
      div(class = "btn-row", actionButton(ns("save"), "Save", class = "btn-brand"), actionButton(ns("test"), "Test", class = "btn-ghost"),
          actionButton(ns("backup"), "Back up all tables now", class = "btn-ghost", icon = icon("box-archive"))),
      uiOutput(ns("last")),
      uiOutput(ns("result"))))
}

admin_drive_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    observe({ s <- ctx$settings()
      updateRadioButtons(session, "mode", selected = s$drive_mode); updateTextInput(session, "folder_id", value = s$drive_folder_id)
      updateTextInput(session, "path", value = s$drive_local_path); updateCheckboxInput(session, "auto", value = is_true(s$drive_auto_backup)) })
    output$last <- renderUI({ s <- ctx$settings()
      p(class = "small muted", "Last copy of all tables: ", if (nzchar(s$drive_last_backup)) s$drive_last_backup else "never") })
    observeEvent(input$backup, {
      req(ctx$admin_ok())
      r <- withProgress(message = "Copying every table to Google Drive...", tryCatch(drive_backup_tables(ctx$settings(), ctx$user()),
                        error = function(e) list(error = safe_error_text(e))))
      ctx$bump()
      output$result <- renderUI(if (!is.null(r$error)) note("bad", r$error) else
        note(if (length(r$problems)) "warn" else "ok", sprintf("Copied %d of %d tables to %s.", r$saved, r$total, r$folder)))
    })
    output$sa <- renderUI({ e <- sa_client_email()
      p(class = "small muted", "Service account: ", if (nzchar(e)) tags$code(e) else "no key yet (Admin > Storage)") })
    observeEvent(input$save, {
      req(ctx$admin_ok()); s <- ctx$settings()
      new <- list(drive_mode = input$mode, drive_folder_id = trimws(sub(".*/folders/", "", sub("\\?.*$", "", input$folder_id %||% ""))),
                  drive_local_path = gsub("\\\\", "/", trimws(input$path %||% "")),
                  drive_auto_backup = if (isTRUE(input$auto)) "TRUE" else "FALSE")
      for (k in names(new)) if (!identical(as.character(s[[k]]), new[[k]])) set_setting(k, new[[k]], ctx$user())
      ctx$bump(); showNotification("Saved.", type = "message")
    })
    observeEvent(input$test, {
      req(ctx$admin_ok())
      s <- modifyList(ctx$settings(), list(drive_mode = input$mode, drive_folder_id = trimws(sub(".*/folders/", "", input$folder_id %||% "")),
                                           drive_local_path = gsub("\\\\", "/", trimws(input$path %||% ""))))
      r <- tryCatch(drive_test(s), error = function(e) list(ok = FALSE, msg = safe_error_text(e)))
      output$result <- renderUI(note(if (r$ok) "ok" else "bad", r$msg))
    })
  })
}
