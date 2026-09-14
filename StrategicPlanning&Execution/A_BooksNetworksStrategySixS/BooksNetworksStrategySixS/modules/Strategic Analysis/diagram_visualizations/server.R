# modules/Strategic Analysis/diagram_visualizations/server.R

diagram_visualizations_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    # ------------------------------------------------------------
    # Category -> Domain -> Topic -> Diagram cascade.
    #
    # This is ONE unified observe() block (not four separate observers
    # each keyed on a different input) precisely to eliminate the failure
    # mode that kept surfacing: a fresh diagram appearing in the CHOICES
    # of a dropdown while the SELECTED value stayed on whatever the
    # person had picked before, because "preserve the current selection
    # if it's still valid" is exactly what silently hides a new upload -
    # the new topic/diagram is technically present in the list, but
    # nothing ever points the screen at it. A single block computing the
    # whole cascade top-to-bottom every time is easier to reason about
    # and test than four interdependent observers, and it lets one rule
    # apply consistently everywhere: whenever a GENUINELY NEW diagram
    # appears (its created_at is newer than the newest one we'd already
    # seen), every dropdown jumps straight to it. Otherwise (the person
    # is just manually browsing older diagrams), the current selection at
    # each level is preserved if it's still valid, same as before.
    #
    # It depends on viz_taxonomy() (so it reruns on every fresh BigQuery
    # pull) AND on input$viz_category / input$viz_domain / input$viz_topic
    # (so it also reruns when the person manually changes an upstream
    # dropdown) - observe() tracks every reactive read in its body, so
    # both triggers are covered without needing separate observers.
    # ------------------------------------------------------------
    viz_taxonomy <- reactive({
      api_manager$state_trigger_diagram()
      if (!api_manager$bq_authenticated) return(api_manager$empty_diagram_taxonomy())
      tryCatch(api_manager$bq_get_diagram_taxonomy(), error = function(e) api_manager$empty_diagram_taxonomy())
    })

    newest_seen_created_at <- reactiveVal(NULL)

    observe({
      tax <- viz_taxonomy()

      cat("--------------------------------------------------------\n")
      cat(sprintf("🔎 [Strategic Analysis][DEBUG] Visualizations cascade recomputed: taxonomy has %d diagram(s)\n", nrow(tax)))

      if (nrow(tax) == 0) {
        updateSelectInput(session, "viz_category", choices = c("(no categories yet)" = ""))
        updateSelectInput(session, "viz_domain", choices = c("(select a category first)" = ""))
        updateSelectInput(session, "viz_topic", choices = c("(select a domain first)" = ""))
        updateSelectInput(session, "viz_diagram_id", choices = c("(select a topic first)" = ""))
        cat("    no diagrams in BigQuery yet - all dropdowns cleared\n")
        return()
      }

      # ---- Detect a genuinely new upload since the last time this block
      #     ran, and if so, force every level to point at it. ----
      newest_row <- tax[which.max(tax$created_at), ]
      previous_newest <- isolate(newest_seen_created_at())
      is_new_upload <- is.null(previous_newest) || newest_row$created_at > previous_newest
      if (is_new_upload) {
        newest_seen_created_at(newest_row$created_at)
        cat(sprintf("    NEW upload detected -> jumping to diagram_id=%s (topic: %s)\n", newest_row$diagram_id, newest_row$topic))
      }

      # ---- Category ----
      categories <- sort(unique(tax$category[nchar(trimws(tax$category)) > 0]))
      cur_cat <- isolate(input$viz_category)
      target_cat <- if (is_new_upload) {
        newest_row$category
      } else if (!is.null(cur_cat) && cur_cat %in% categories) {
        cur_cat
      } else {
        categories[1]
      }
      updateSelectInput(session, "viz_category", choices = setNames(categories, categories), selected = target_cat)

      # ---- Domain ----
      domains <- sort(unique(tax$domain[tax$category == target_cat & nchar(trimws(tax$domain)) > 0]))
      if (length(domains) == 0) {
        updateSelectInput(session, "viz_domain", choices = c("(no domains found)" = ""))
        updateSelectInput(session, "viz_topic", choices = c("(select a domain first)" = ""))
        updateSelectInput(session, "viz_diagram_id", choices = c("(select a topic first)" = ""))
        return()
      }
      cur_dom <- isolate(input$viz_domain)
      target_dom <- if (is_new_upload) {
        newest_row$domain
      } else if (!is.null(cur_dom) && cur_dom %in% domains) {
        cur_dom
      } else {
        domains[1]
      }
      updateSelectInput(session, "viz_domain", choices = setNames(domains, domains), selected = target_dom)

      # ---- Topic ----
      topics <- sort(unique(tax$topic[tax$category == target_cat & tax$domain == target_dom & nchar(trimws(tax$topic)) > 0]))
      if (length(topics) == 0) {
        updateSelectInput(session, "viz_topic", choices = c("(no topics found)" = ""))
        updateSelectInput(session, "viz_diagram_id", choices = c("(select a topic first)" = ""))
        return()
      }
      cur_top <- isolate(input$viz_topic)
      target_top <- if (is_new_upload) {
        newest_row$topic
      } else if (!is.null(cur_top) && cur_top %in% topics) {
        cur_top
      } else {
        topics[1]
      }
      updateSelectInput(session, "viz_topic", choices = setNames(topics, topics), selected = target_top)

      # ---- Diagram ----
      diagrams <- tax[tax$category == target_cat & tax$domain == target_dom & tax$topic == target_top, , drop = FALSE]
      if (nrow(diagrams) == 0) {
        updateSelectInput(session, "viz_diagram_id", choices = c("(no diagrams found)" = ""))
        return()
      }
      labels <- sprintf("%s - %s (%s)", diagrams$diagram_name, diagrams$title,
                        ifelse(diagrams$is_template, "template", "generated"))
      cur_diag <- isolate(input$viz_diagram_id)
      target_diag <- if (is_new_upload) {
        newest_row$diagram_id
      } else if (!is.null(cur_diag) && cur_diag %in% diagrams$diagram_id) {
        cur_diag
      } else {
        diagrams$diagram_id[1]
      }
      updateSelectInput(session, "viz_diagram_id", choices = setNames(diagrams$diagram_id, labels), selected = target_diag)

      cat(sprintf("    resolved: Category=%s | Domain=%s | Topic=%s | diagram_id=%s\n", target_cat, target_dom, target_top, target_diag))
      cat("--------------------------------------------------------\n")
    })

    # Explicit manual fallback: clears the taxonomy cache and forces a
    # genuinely fresh BigQuery pull, in case anything upstream (a browser
    # tab that's been open a while, a slow-to-propagate trigger) left the
    # in-memory taxonomy stale. This bypasses every layer of automatic
    # reactivity above and unconditionally re-fetches.
    observeEvent(input$refresh, {
      cat("🔄 [Strategic Analysis][DEBUG] Manual refresh requested - clearing taxonomy cache and re-querying BigQuery\n")
      api_manager$diagram_taxonomy_cache <- NULL
      api_manager$trigger_state_update_diagram()
      showNotification("Diagram list refreshed from BigQuery.", type = "message")
    })


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
        cat(sprintf("    category/domain/topic : %s / %s / %s\n", components$category[1], components$domain[1], components$topic[1]))
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
