# modules/Six Sigma Analysis/sixsigma_visualizations/server.R

sixsigma_visualizations_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    # ------------------------------------------------------------
    # Category -> Domain -> Topic -> Diagram cascade, same pattern as
    # Strategic Analysis's diagram_visualizations and Knowledge Graph's
    # visualize_kg_d3 - four short, chained dropdowns instead of one
    # mega-dropdown. The Diagram label includes the specific tool name
    # (e.g. "Fishbone / Ishikawa Diagram") so picking among several
    # diagrams under the same topic is unambiguous even without a
    # separate Group/Type filter at this stage.
    # ------------------------------------------------------------
    viz_taxonomy <- reactive({
      api_manager$state_trigger_sixsigma()
      if (!api_manager$bq_authenticated) return(api_manager$empty_sixsigma_taxonomy())
      tryCatch(api_manager$bq_get_sixsigma_taxonomy(), error = function(e) api_manager$empty_sixsigma_taxonomy())
    })

    observeEvent(viz_taxonomy(), {
      tax <- viz_taxonomy()
      categories <- sort(unique(tax$category[nchar(trimws(tax$category)) > 0]))
      if (length(categories) == 0) {
        updateSelectInput(session, "viz_category", choices = c("(no categories yet)" = ""))
      } else {
        current <- isolate(input$viz_category)
        selected <- if (!is.null(current) && current %in% categories) current else categories[1]
        updateSelectInput(session, "viz_category", choices = setNames(categories, categories), selected = selected)
      }
    }, ignoreNULL = FALSE)

    observeEvent(input$viz_category, {
      tax <- viz_taxonomy()
      if (is.null(input$viz_category) || input$viz_category == "") {
        updateSelectInput(session, "viz_domain", choices = c("(select a category first)" = ""))
        return()
      }
      domains <- sort(unique(tax$domain[tax$category == input$viz_category & nchar(trimws(tax$domain)) > 0]))
      if (length(domains) == 0) {
        updateSelectInput(session, "viz_domain", choices = c("(no domains found)" = ""))
      } else {
        updateSelectInput(session, "viz_domain", choices = setNames(domains, domains))
      }
    }, ignoreInit = TRUE)

    observeEvent(input$viz_domain, {
      tax <- viz_taxonomy()
      if (is.null(input$viz_category) || is.null(input$viz_domain) ||
          input$viz_category == "" || input$viz_domain == "") {
        updateSelectInput(session, "viz_topic", choices = c("(select a domain first)" = ""))
        return()
      }
      topics <- sort(unique(tax$topic[tax$category == input$viz_category &
                                       tax$domain == input$viz_domain &
                                       nchar(trimws(tax$topic)) > 0]))
      if (length(topics) == 0) {
        updateSelectInput(session, "viz_topic", choices = c("(no topics found)" = ""))
      } else {
        updateSelectInput(session, "viz_topic", choices = setNames(topics, topics))
      }
    }, ignoreInit = TRUE)

    observeEvent(input$viz_topic, {
      if (!api_manager$bq_authenticated || is.null(input$viz_category) || is.null(input$viz_domain) ||
          is.null(input$viz_topic) || input$viz_category == "" || input$viz_domain == "" ||
          input$viz_topic == "") {
        updateSelectInput(session, "viz_diagram_id", choices = c("(select a topic first)" = ""))
        return()
      }

      tax <- viz_taxonomy()
      diagrams <- tax[tax$category == input$viz_category & tax$domain == input$viz_domain &
                       tax$topic == input$viz_topic, , drop = FALSE]
      if (nrow(diagrams) == 0) {
        updateSelectInput(session, "viz_diagram_id", choices = c("(no diagrams found)" = ""))
      } else {
        labels <- sprintf("%s - %s (%s)", diagrams$diagram_name, diagrams$title,
                          ifelse(diagrams$is_template, "template", "generated"))
        updateSelectInput(session, "viz_diagram_id", choices = setNames(diagrams$diagram_id, labels))
      }
    }, ignoreInit = TRUE)

    # ------------------------------------------------------------
    # Pull + render the selected diagram
    # ------------------------------------------------------------
    observeEvent(input$view, {
      diag_id <- input$viz_diagram_id
      if (is.null(diag_id) || nchar(trimws(diag_id)) == 0) {
        showNotification("No diagram selected.", type = "warning")
        return()
      }

      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Loading diagram...") })

      cat("========================================================\n")
      cat("📥 [Six Sigma Analysis][DEBUG] Visualizations tab: pulling diagram from BigQuery\n")
      cat(sprintf("    diagram_id : %s\n", diag_id))
      t0 <- Sys.time()

      tryCatch({
        components <- api_manager$bq_get_sixsigma_components(diag_id)
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
        cat(sprintf("    diagram_type  : %s (group: %s)\n", diagram_type, components$diagram_group[1]))
        cat(sprintf("    diagram_name  : %s | title: %s\n", components$diagram_name[1], components$title[1]))
        cat(sprintf("    category/domain/topic : %s / %s / %s\n", components$category[1], components$domain[1], components$topic[1]))
        cat("    component_type breakdown:\n")
        for (ct_name in names(component_type_counts)) {
          cat(sprintf("      - %-20s : %d\n", ct_name, component_type_counts[[ct_name]]))
        }
        if (diagram_type == "fmea_table") {
          n_fmea <- sum(!is.na(components$severity))
          cat(sprintf("    FMEA rows with S/O/D set : %d (RPN will be computed at render time)\n", n_fmea))
        }
        if (diagram_type %in% c("sipoc", "doe_table", "pugh_matrix") && all(is.na(components$grid_col))) {
          cat("    ⚠️  WARNING: diagram_type expects grid_col but all values are NA - layout may be degenerate\n")
        }
        cat("========================================================\n")

        render_t0 <- Sys.time()
        rendered <- render_sixsigma(components, diagram_type)
        render_elapsed <- round(as.numeric(difftime(Sys.time(), render_t0, units = "secs")), 3)
        cat(sprintf("🎨 [Six Sigma Analysis][DEBUG] render_sixsigma() completed in %ss\n", render_elapsed))

        output$diagram_output <- renderUI({ rendered })
        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Rendered %d component(s) as '%s'", nrow(components), diagram_type))
        })

      }, error = function(e) {
        cat(sprintf("❌ [Six Sigma Analysis][DEBUG] Visualization failed: %s\n", e$message))
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
