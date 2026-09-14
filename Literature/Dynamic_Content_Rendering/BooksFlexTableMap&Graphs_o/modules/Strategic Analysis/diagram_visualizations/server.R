# modules/Strategic Analysis/diagram_visualizations/server.R

diagram_visualizations_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    setup_diagram_picker(input, output, session, api_manager, input_id = "diagram_select")

    observeEvent(input$view, {
      diag_id <- input$diagram_select
      if (is.null(diag_id) || nchar(trimws(diag_id)) == 0) {
        showNotification("No diagram selected.", type = "warning")
        return()
      }

      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Loading diagram...") })

      # ---- DEBUG: printed every time a diagram is pulled from BigQuery
      #     for display, including timing for the query itself. ----------
      cat("========================================================\n")
      cat("📥 [Strategic Analysis][DEBUG] Visualizations tab: pulling diagram from BigQuery\n")
      cat(sprintf("    diagram_id : %s\n", diag_id))
      t0 <- Sys.time()

      tryCatch({
        components <- api_manager$bq_get_diagram_components(diag_id)
        query_elapsed <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 2)

        if (nrow(components) == 0) {
          cat(sprintf("    result     : 0 rows returned in %ss - nothing to render\n", query_elapsed))
          cat("========================================================\n")
          output$status <- renderUI({
            tags$div(class = "status-warning", tags$i(class = "fa fa-exclamation-triangle"), " No components found for this diagram_id.")
          })
          output$diagram_output <- renderUI({ tags$div() })
          return()
        }

        diagram_type <- components$diagram_type[1]
        component_type_counts <- table(components$component_type)

        cat(sprintf("    result     : %d row(s) returned in %ss\n", nrow(components), query_elapsed))
        cat(sprintf("    diagram_type : %s\n", diagram_type))
        cat(sprintf("    diagram_name : %s | title: %s\n", components$diagram_name[1], components$title[1]))
        cat(sprintf("    category/topic : %s / %s\n", components$category[1], components$topic[1]))
        cat("    component_type breakdown:\n")
        for (ct_name in names(component_type_counts)) {
          cat(sprintf("      - %-20s : %d\n", ct_name, component_type_counts[[ct_name]]))
        }
        # Sanity check: any grid_col/grid_row without a matching diagram_type
        # would indicate a bad upload - flagged here, not silently rendered.
        if (diagram_type %in% c("grid", "table") && all(is.na(components$grid_col))) {
          cat("    ⚠️  WARNING: diagram_type expects grid_col but all values are NA - layout may be degenerate\n")
        }
        cat("========================================================\n")

        render_t0 <- Sys.time()
        rendered <- render_diagram(components, diagram_type)
        render_elapsed <- round(as.numeric(difftime(Sys.time(), render_t0, units = "secs")), 3)
        cat(sprintf("🎨 [Strategic Analysis][DEBUG] render_diagram() completed in %ss\n", render_elapsed))

        output$diagram_output <- renderUI({ rendered })
        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Rendered %d component(s) as '%s'", nrow(components), diagram_type))
        })

      }, error = function(e) {
        cat(sprintf("❌ [Strategic Analysis][DEBUG] Visualization failed: %s\n", e$message))
        cat("========================================================\n")
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        output$diagram_output <- renderUI({ tags$div() })
      })
    })

    output$status <- renderUI({ tags$div() })
    output$diagram_output <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
