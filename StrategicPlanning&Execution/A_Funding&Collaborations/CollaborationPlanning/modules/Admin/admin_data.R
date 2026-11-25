# ---- module ----------------------------------------------
# id:           admin_data
# name:         Data import
# icon:         file-import
# description:  One-off import from the older apps: Funding Programmes (BigQuery) and Grant Compass (CSV)
# packages:     shiny
# -----------------------------------------------------------

admin_data_ui <- function(id) {
  ns <- NS(id)
  tagList(
    note("info", "Bring the programmes you already have into this app. Programmes already here (same funder and name) ",
         "are skipped, so running an import twice is safe. Imported programmes start at the Discover stage."),
    card("From the Funding Programmes app (BigQuery)",
      p(class = "small muted", "Reads the old table that the Funding Programmes app and the Business Operations Suite write to. ",
        "Needs BigQuery connected in Storage."),
      div(class = "btn-row",
          textInput(ns("bq_table"), "Table", value = "atera-2.business_strategy.funding_programmes", width = "420px"),
          actionButton(ns("import_bq"), "Import", class = "btn-brand")),
      uiOutput(ns("bq_status"))),
    card("From Grant Compass (CSV)",
      p(class = "small muted", "In Grant Compass, open Admin and download the Grants table as CSV ",
        "(or download the Grants tab of its Google Sheet), then choose the file here."),
      fileInput(ns("gc_csv"), NULL, accept = ".csv", buttonLabel = "Choose CSV"),
      uiOutput(ns("gc_status"))))
}

admin_data_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$import_bq, {
      req(ctx$admin_ok())
      res <- tryCatch({
        if (!isTRUE(store_status()$bq_ok) && !isTRUE(store_status()$bq_configured)) stop("BigQuery is not set up. See Admin > Storage.")
        raw <- withProgress(message = "Reading BigQuery...", bq_read_external(trimws(input$bq_table)))
        r <- add_programmes(map_programme_columns(raw, source = "Funding Programmes app"), ctx$user())
        note("ok", sprintf("Read %d rows. Added %d, skipped %d already here.", nrow(raw), r$added, r$skipped))
      }, error = function(e) note("bad", safe_error_text(e)))
      output$bq_status <- renderUI(res); ctx$bump()
    })
    observeEvent(input$gc_csv, {
      req(ctx$admin_ok())
      res <- tryCatch({
        raw <- utils::read.csv(input$gc_csv$datapath, stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE)
        r <- add_programmes(map_programme_columns(raw, source = "Grant Compass"), ctx$user())
        note("ok", sprintf("Read %d rows. Added %d, skipped %d already here.", nrow(raw), r$added, r$skipped))
      }, error = function(e) note("bad", safe_error_text(e)))
      output$gc_status <- renderUI(res); ctx$bump()
    })
  })
}
