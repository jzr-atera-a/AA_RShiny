# ---- module ----------------------------------------------
# id:           admin_storage
# name:         Storage
# icon:         database
# description:  Google Sheet and BigQuery status, reconnect, and copy a table from the Sheet to BigQuery
# packages:     shiny
# -----------------------------------------------------------

admin_storage_ui <- function(id) {
  ns <- NS(id)
  tagList(
    note("info", "The app saves to both the Google Sheet and BigQuery. It reads from the Sheet when it is connected, ",
         "otherwise from BigQuery, otherwise from CSV files in the app's data folder (testing only: files on shinyapps.io ",
         "are lost when the app restarts)."),
    uiOutput(ns("status")),
    div(class = "btn-row",
        actionButton(ns("reconnect"), "Reconnect", class = "btn-brand", icon = icon("rotate")),
        actionButton(ns("clear"), "Clear read cache", class = "btn-ghost")),
    card("Copy a table from the Sheet to BigQuery",
      p(class = "small muted", "Use this after editing a tab directly in the Sheet, so BigQuery holds the same rows. ",
        "It replaces the BigQuery table with the Sheet's rows."),
      div(class = "btn-row",
          selectInput(ns("sync_tab"), NULL, names(SCHEMAS), selected = "allowed_emails", width = "240px"),
          actionButton(ns("sync"), "Copy now", class = "btn-ghost")),
      uiOutput(ns("sync_status"))),
    card("How to set it up",
      tags$ol(
        tags$li("In Google Cloud, create a service account, enable the Google Sheets API and the BigQuery API, and download its JSON key."),
        tags$li("Save the key in the app folder as ", tags$code("auth/google_service_account.json"), " (it is bundled when you deploy)."),
        tags$li("Create a Google Sheet and share it with the service account's email as Editor."),
        tags$li("Give the service account the BigQuery Data Editor and Job User roles on your project."),
        tags$li("Set the variables ", tags$code("GOOGLE_SHEETS_ID"), ", ", tags$code("CP_BQ_PROJECT"), " and ",
                tags$code("CP_BQ_DATASET"), " in .Renviron locally, or in shinyapps.io > Settings > Variables."),
        tags$li("Press Reconnect. Missing tabs and tables are created with their headers."))))
}

admin_storage_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    refresh <- reactiveVal(0)

    output$status <- renderUI({
      req(ctx$admin_ok()); refresh(); ctx$tick()
      st <- store_status()
      layout_columns(col_widths = c(6, 6),
        card("Google Sheet",
          status_pill(st$sheet_ok, no = if (st$sheet_configured) "Error" else "Not set up"),
          tags$table(class = "kv",
            tags$tr(tags$th("Sheet id"), tags$td(if (nzchar(cfg$sheet_id)) cfg$sheet_id else "GOOGLE_SHEETS_ID not set")),
            tags$tr(tags$th("Key file"), tags$td(if (sa_key_available()) cfg$sa_key_path else paste(cfg$sa_key_path, "(missing)"))),
            tags$tr(tags$th("Service account"), tags$td(if (nzchar(st$sa_email)) st$sa_email else "-"))),
          if (nzchar(st$sheet_error)) note("bad", st$sheet_error),
          if (nzchar(cfg$sheet_id)) tags$a(href = paste0("https://docs.google.com/spreadsheets/d/", cfg$sheet_id),
                                           target = "_blank", rel = "noopener", "Open the Sheet")),
        card("BigQuery",
          status_pill(st$bq_ok, no = if (st$bq_configured) "Error" else "Not set up"),
          tags$table(class = "kv",
            tags$tr(tags$th("Project"), tags$td(if (nzchar(cfg$bq_project)) cfg$bq_project else "CP_BQ_PROJECT not set")),
            tags$tr(tags$th("Dataset"), tags$td(cfg$bq_dataset)),
            tags$tr(tags$th("Table prefix"), tags$td(cfg$bq_prefix)),
            tags$tr(tags$th("bigrquery"), tags$td(if (bq_available()) "installed" else "not installed"))),
          if (nzchar(st$bq_error)) note("bad", st$bq_error)),
        card("Reading from", tags$b(st$read_from),
             if (store_mode_csv()) note("warn", "Testing mode: data is kept in local CSV files only.")))
    })

    observeEvent(input$reconnect, {
      req(ctx$admin_ok())
      withProgress(message = "Connecting...", store_init())
      log_change(ctx$user(), "reconnect", "storage", store_read_from())
      refresh(refresh() + 1); ctx$bump()
    })
    observeEvent(input$clear, { req(ctx$admin_ok()); store_clear_cache(); ctx$bump(); showNotification("Cache cleared.") })

    observeEvent(input$sync, {
      req(ctx$admin_ok())
      res <- tryCatch(note("ok", sprintf("Copied %d rows of %s to BigQuery.", store_sync_sheet_to_bq(input$sync_tab, ctx$user()), input$sync_tab)),
                      error = function(e) note("bad", safe_error_text(e)))
      output$sync_status <- renderUI(res)
    })
  })
}
