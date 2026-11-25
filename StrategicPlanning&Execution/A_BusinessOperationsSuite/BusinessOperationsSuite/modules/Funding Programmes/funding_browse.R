# modules/Funding Programmes/funding_browse.R
# Updated from DaysPlanningFundingTravel (modules/Funding Programmes/funding_browse/ui.R + server.R)

funding_browse_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Browse Planned Programmes", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(2, actionButton(ns("refresh"), "Refresh Data", class = "btn-primary", icon = icon("sync"))),
            column(2, downloadButton(ns("download"), "Download CSV", class = "btn-info")),
            column(2, downloadButton(ns("download_calendar"), "📅 Calendar", class = "btn-success"),
                      actionButton(ns("to_collab"), "To CollaborationPlanning folder", icon = icon("share-square"), class = "btn-warning btn-xs",
                                   style = "margin-top:4px;", title = "One CSV per country and category, in its Country/Category/Topic folders")),
            column(3, numericInput(ns("max_rows"), "Max Rows to Display:", value = 200, min = 10, max = 2000, step = 10)),
            column(3, selectInput(ns("show"), "Show:", choices = c("All rows" = "all", "Only repeated" = "repeated",
                                                                   "Only from CollaborationPlanning" = "collab", "Only added in this app" = "ours")))
          ),
          br(), htmlOutput(ns("status")),
          tags$p(class = "help-block", "Rows highlighted in amber are repeated: the same programme was already in the table when it was ",
                 "imported from CollaborationPlanning (Funding Programmes > Collaboration Sync)."),
          DT::dataTableOutput(ns("table"))
      )
    )
  )
}

funding_browse_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    # Calendar helpers (generate_calendar_ics / export_calendar_file) come from
    # R/utils_calendar_export.R, sourced once in global.R.

    browse_data <- reactiveVal(NULL)

    observeEvent(input$refresh, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Loading data...") })

      tryCatch({
        query <- sprintf("SELECT * FROM `%s` ORDER BY deadline ASC, category ASC LIMIT %d",
                        api_manager$bq_full_table_funding, input$max_rows)
        data <- api_manager$bq_query(query)
        browse_data(data)

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), sprintf(" Loaded %d rows", nrow(data)))
        })
        showNotification(sprintf("✓ Loaded %d rows", nrow(data)), type = "message")

      }, error = function(e) {
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    # the loaded rows, one CSV per country + category, into CollaborationPlanning's Country/Category/Topic folders
    observeEvent(input$to_collab, {
      d <- browse_data()
      if (is.null(d) || !nrow(d)) return(output$status <- renderUI(tags$div(class = "status-warning", " Load the data first (Refresh Data).")))
      res <- withProgress(message = "Writing to CollaborationPlanning's folder...", tryCatch({
        s <- collab_load_settings(); sa <- tryCatch(cred_local()$json_path, error = function(e) NA)
        if (!collab_ready(s, sa)) stop("The CollaborationPlanning folder is not set up (API Settings > Google Drive > CollaborationPlanning).", call. = FALSE)
        key <- paste(collab_chr(d$country), collab_chr(d$category), sep = "\r")
        out <- character(0)
        for (k in unique(key)) {
          part <- d[key == k, , drop = FALSE]
          tf <- tempfile(fileext = ".csv"); utils::write.csv(part, tf, row.names = FALSE, fileEncoding = "UTF-8")
          out <- c(out, collab_write_outputs(collab_output_levels(part$country[1], part$category[1], s), "funding_programmes",
                                             list(list(ext = "csv", bytes = readBin(tf, "raw", file.info(tf)$size))), s, sa))
          incProgress(1 / length(unique(key)))
        }
        out
      }, error = function(e) e))
      output$status <- renderUI(if (inherits(res, "error")) tags$div(class = "status-error", " Not written: ", conditionMessage(res)) else
        tags$div(class = "status-success", sprintf(" ✓ %d CSV file(s) written to CollaborationPlanning's folder.", length(res)),
                 tags$details(tags$summary("Files"), tags$pre(paste(res, collapse = "\n")))))
    })

    output$download <- downloadHandler(
      filename = function() paste0("funding_programmes_", format(Sys.Date(), "%Y%m%d"), ".csv"),
      content = function(file) if (!is.null(browse_data())) write.csv(browse_data(), file, row.names = FALSE)
    )

    # deadlines (+ application-open dates) with reminders, in each programme's saved time zone (R/utils_ics.R)
    output$download_calendar <- downloadHandler(
      filename = function() ics_filename("funding_deadlines"),
      content = function(file) {
        res <- ics_safe_build(ics_events_funding, browse_data(), include_opens = TRUE, alarms = TRUE)
        if (!length(res$events)) showNotification("No funding programmes with a date to export", type = "warning")
        else showNotification(sprintf("\u2713 %d calendar event(s) exported", length(res$events)), type = "message")
        ics_write_safe(function() res$events, "Funding Programmes", file)
      },
      contentType = "text/calendar")

    output$status <- renderUI({ tags$div() })

    # the table, with the Show filter; repeated rows (imports from CollaborationPlanning) in amber
    output$table <- DT::renderDataTable({
      data <- browse_data(); req(data)
      src <- if ("source" %in% names(data)) as.character(data$source) else rep(NA_character_, nrow(data))
      rep_ <- if ("repeated" %in% names(data)) toupper(as.character(data$repeated)) == "TRUE" else rep(FALSE, nrow(data))
      rep_[is.na(rep_)] <- FALSE
      keep <- switch(input$show %||% "all", repeated = rep_, collab = !is.na(src) & startsWith(src, "CollaborationPlanning"),
                     ours = is.na(src) | !startsWith(src, "CollaborationPlanning"), rep(TRUE, nrow(data)))
      d <- data[keep, , drop = FALSE]
      dt <- DT::datatable(d, options = list(pageLength = 25, scrollX = TRUE), rownames = FALSE)
      if ("repeated" %in% names(d)) dt <- DT::formatStyle(dt, "repeated", target = "row", backgroundColor = DT::styleEqual(c("TRUE", "true"), c("#fff3cd", "#fff3cd")))
      dt
    })
    output$table <- DT::renderDataTable({})
    session$onSessionEnded(function() {})
  })
}
