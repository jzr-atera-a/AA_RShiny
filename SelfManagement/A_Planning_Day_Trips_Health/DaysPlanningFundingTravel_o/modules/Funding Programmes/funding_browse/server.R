# modules/Funding Programmes/funding_browse/server.R

funding_browse_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    source("R/utils_calendar_export.R", local = TRUE)

    # Source calendar utility

    browse_data <- reactiveVal(NULL)

    observeEvent(input$refresh, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Loading data...") })

      tryCatch({
        query <- sprintf("SELECT * FROM `%s` ORDER BY deadline ASC, category ASC LIMIT %d",
                        api_manager$bq_full_table_funding, input$max_rows)
        data <- api_manager$bq_query(query)
        browse_data(data)

        output$table <- DT::renderDataTable({
          DT::datatable(data, options = list(pageLength = 25, scrollX = TRUE), rownames = FALSE)
        })
        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), sprintf(" Loaded %d rows", nrow(data)))
        })
        showNotification(sprintf("✓ Loaded %d rows", nrow(data)), type = "message")

      }, error = function(e) {
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$download <- downloadHandler(
      filename = function() paste0("funding_programmes_", format(Sys.Date(), "%Y%m%d"), ".csv"),
      content = function(file) if (!is.null(browse_data())) write.csv(browse_data(), file, row.names = FALSE)
    )

    output$download_calendar <- downloadHandler(
      filename = function() paste0("funding_deadlines_", format(Sys.Date(), "%Y%m%d"), ".ics"),
      content = function(file) {
        tryCatch({
          data <- browse_data()
          if (is.null(data) || nrow(data) == 0) {
            showNotification("No funding programmes to export", type = "warning")
            return()
          }

          # Rename columns for calendar export
          cal_data <- data
          if ("deadline" %in% names(cal_data)) names(cal_data)[names(cal_data) == "deadline"] <- "date"
          if ("programme_name" %in% names(cal_data)) names(cal_data)[names(cal_data) == "programme_name"] <- "name"
          if ("title" %in% names(cal_data)) names(cal_data)[names(cal_data) == "title"] <- "name"

          ics_lines <- generate_calendar_ics(
            title = "Funding Programme Deadlines",
            items = cal_data,
            date_col = "date",
            duration_minutes = 480,  # All-day events
            description = "Funding application deadline - Exported from Business Operations Suite",
            item_col = if ("name" %in% names(cal_data)) "name" else "programme_name"
          )

          export_calendar_file(ics_lines, file)
          showNotification("✓ Funding deadlines exported successfully", type = "message")

        }, error = function(e) {
          showNotification(paste("Error exporting calendar:", e$message), type = "error")
        })
      }
    )

    output$status <- renderUI({ tags$div() })
    output$table <- DT::renderDataTable({})
    session$onSessionEnded(function() {})
  })
}
