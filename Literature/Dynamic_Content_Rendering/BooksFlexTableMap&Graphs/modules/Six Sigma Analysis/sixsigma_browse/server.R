# modules/Six Sigma Analysis/sixsigma_browse/server.R

sixsigma_browse_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    catalog_data <- reactiveVal(NULL)
    component_data <- reactiveVal(NULL)

    load_data <- function() {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Loading data...") })

      tryCatch({
        api_manager$sixsigma_taxonomy_cache <- NULL
        catalog <- api_manager$bq_get_sixsigma_taxonomy()
        catalog_data(catalog)

        output$catalog_table <- DT::renderDataTable({
          DT::datatable(catalog, options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE)
        })

        query <- if (nchar(trimws(input$filter_diagram_id %||% "")) > 0) {
          sprintf("SELECT * FROM `%s` WHERE diagram_id = '%s' ORDER BY diagram_id, grid_row, grid_col, sequence_order LIMIT %d",
                  api_manager$bq_full_table_sixsigma, safe_sql_escape(trimws(input$filter_diagram_id)), input$max_rows)
        } else {
          sprintf("SELECT * FROM `%s` ORDER BY created_at DESC LIMIT %d",
                  api_manager$bq_full_table_sixsigma, input$max_rows)
        }
        components <- api_manager$bq_query(query)
        component_data(components)

        output$component_table <- DT::renderDataTable({
          DT::datatable(components, options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE)
        })

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Loaded %d diagram(s), %d component row(s)", nrow(catalog), nrow(components)))
        })
      }, error = function(e) {
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    }

    observeEvent(input$refresh, load_data())
    observeEvent(input$filter_diagram_id, load_data())

    output$download_catalog <- downloadHandler(
      filename = function() paste0("sixsigma_catalog_", format(Sys.Date(), "%Y%m%d"), ".csv"),
      content = function(file) if (!is.null(catalog_data())) write.csv(catalog_data(), file, row.names = FALSE)
    )
    output$download_components <- downloadHandler(
      filename = function() paste0("sixsigma_components_", format(Sys.Date(), "%Y%m%d"), ".csv"),
      content = function(file) if (!is.null(component_data())) write.csv(component_data(), file, row.names = FALSE)
    )

    output$status <- renderUI({ tags$div() })
    output$catalog_table <- DT::renderDataTable({})
    output$component_table <- DT::renderDataTable({})
    session$onSessionEnded(function() {})
  })
}
