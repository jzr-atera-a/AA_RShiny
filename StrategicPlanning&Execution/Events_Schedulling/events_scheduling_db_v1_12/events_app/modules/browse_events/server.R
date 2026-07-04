# modules/browse_events/server.R

browse_events_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    all_data   <- reactiveVal(NULL)
    filter_data <- reactiveVal(NULL)

    load_data <- function() {
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Loading data...")
      })

      tryCatch({
        query <- sprintf(
          "SELECT event_name, organiser, city, country, category, subcategory,
                  event_date, event_time, venue_name, address, latitude, longitude,
                  description, ticket_url, price_range, source_url, scan_date, created_at
           FROM `%s` ORDER BY event_date ASC, created_at DESC LIMIT %d",
          api_manager$bq_full_table_id, input$max_rows
        )
        data <- api_manager$bq_query(query)
        all_data(data)

        # Populate filter dropdowns
        if (nrow(data) > 0) {
          cities <- sort(unique(data$city[nchar(trimws(data$city)) > 0]))
          updateSelectInput(session, "filter_city",
                            choices = c("All" = "", setNames(cities, cities)),
                            selected = "")

          cats <- sort(unique(data$category[nchar(trimws(data$category)) > 0]))
          updateSelectInput(session, "filter_category",
                            choices = c("All" = "", setNames(cats, cats)),
                            selected = "")
        }

        apply_filters(data)

        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Loaded %d events", nrow(data)))
        })
        showNotification(sprintf("✓ Loaded %d events", nrow(data)), type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
      })
    }

    apply_filters <- function(data = all_data()) {
      if (is.null(data)) return()
      filtered <- data

      if (!is.null(input$filter_city) && input$filter_city != "") {
        filtered <- filtered[filtered$city == input$filter_city, ]
      }
      if (!is.null(input$filter_category) && input$filter_category != "") {
        filtered <- filtered[filtered$category == input$filter_category, ]
      }

      filter_data(filtered)

      display_cols <- c("event_name", "city", "category", "subcategory",
                        "event_date", "event_time", "venue_name", "price_range", "ticket_url")
      display_cols <- intersect(display_cols, names(filtered))

      output$table <- DT::renderDataTable({
        DT::datatable(
          filtered[, display_cols],
          options   = list(pageLength = 25, scrollX = TRUE, dom = "Bfrtip"),
          rownames  = FALSE,
          escape    = FALSE,
          callback  = DT::JS("table.on('click', 'td', function(){});")
        )
      })
    }

    observeEvent(input$refresh, { load_data() })

    observeEvent(api_manager$state_trigger(), {
      if (api_manager$bq_authenticated) load_data()
    }, ignoreInit = TRUE)

    observeEvent(input$filter_city,     { apply_filters() }, ignoreInit = TRUE)
    observeEvent(input$filter_category, { apply_filters() }, ignoreInit = TRUE)

    output$download <- downloadHandler(
      filename = function() paste0("events_", format(Sys.Date(), "%Y%m%d"), ".csv"),
      content  = function(file) {
        d <- if (!is.null(filter_data())) filter_data() else all_data()
        if (!is.null(d)) {
          cat("📥 [browse_events] Downloading CSV:", nrow(d), "rows →", file, "\n")
          write.csv(d, file, row.names = FALSE)
          cat("✅ [browse_events] CSV written\n")
        } else {
          cat("⚠️  [browse_events] No data to download\n")
        }
      }
    )

    output$status <- renderUI({ tags$div() })
    output$table  <- DT::renderDataTable({})
    session$onSessionEnded(function() {})
  })
}
