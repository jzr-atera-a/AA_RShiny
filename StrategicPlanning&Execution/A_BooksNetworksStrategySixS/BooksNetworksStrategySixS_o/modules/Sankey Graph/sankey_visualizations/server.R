# modules/Sankey Graph/sankey_visualizations/server.R

sankey_visualizations_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    # ------------------------------------------------------------
    # Category -> Domain -> Topic -> Sankey cascade.
    #
    # This is ONE unified observe() block (not four separate observers
    # each keyed on a different input), the same design used by Strategic
    # Analysis's diagram_visualizations after a real bug was found there:
    # four separate observeEvent(input$x, ...) blocks fail to notice a
    # fresh BigQuery upload whenever the relevant dropdown's value
    # happens to already equal a valid string (its choices refresh, but
    # nothing points the screen at the new entry, silently hiding it). A
    # single block computing the whole cascade top-to-bottom every time
    # sidesteps that entirely: whenever a genuinely NEW Sankey appears
    # (its created_at is newer than the last one seen), every dropdown
    # jumps straight to it; otherwise (just manually browsing older
    # Sankeys) the current selection at each level is preserved if still
    # valid.
    # ------------------------------------------------------------
    viz_taxonomy <- reactive({
      api_manager$state_trigger_sankey()
      if (!api_manager$bq_authenticated) return(api_manager$empty_sankey_taxonomy())
      tryCatch(api_manager$bq_get_sankey_taxonomy(), error = function(e) api_manager$empty_sankey_taxonomy())
    })

    newest_seen_created_at <- reactiveVal(NULL)

    observe({
      tax <- viz_taxonomy()

      cat("--------------------------------------------------------\n")
      cat(sprintf("🔎 [Sankey Graph][DEBUG] Visualizations cascade recomputed: taxonomy has %d Sankey(s)\n", nrow(tax)))

      if (nrow(tax) == 0) {
        updateSelectInput(session, "viz_category", choices = c("(no categories yet)" = ""))
        updateSelectInput(session, "viz_domain", choices = c("(select a category first)" = ""))
        updateSelectInput(session, "viz_topic", choices = c("(select a domain first)" = ""))
        updateSelectInput(session, "viz_sankey_id", choices = c("(select a topic first)" = ""))
        cat("    no Sankeys in BigQuery yet - all dropdowns cleared\n")
        return()
      }

      newest_row <- tax[which.max(tax$created_at), ]
      previous_newest <- isolate(newest_seen_created_at())
      is_new_upload <- is.null(previous_newest) || newest_row$created_at > previous_newest
      if (is_new_upload) {
        newest_seen_created_at(newest_row$created_at)
        cat(sprintf("    NEW upload detected -> jumping to sankey_id=%s (topic: %s)\n", newest_row$sankey_id, newest_row$topic))
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

      # ---- Domain (Sector) ----
      domains <- sort(unique(tax$domain[tax$category == target_cat & nchar(trimws(tax$domain)) > 0]))
      if (length(domains) == 0) {
        updateSelectInput(session, "viz_domain", choices = c("(no domains found)" = ""))
        updateSelectInput(session, "viz_topic", choices = c("(select a domain first)" = ""))
        updateSelectInput(session, "viz_sankey_id", choices = c("(select a topic first)" = ""))
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
        updateSelectInput(session, "viz_sankey_id", choices = c("(select a topic first)" = ""))
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

      # ---- Sankey (by title) ----
      sankeys <- tax[tax$category == target_cat & tax$domain == target_dom & tax$topic == target_top, , drop = FALSE]
      if (nrow(sankeys) == 0) {
        updateSelectInput(session, "viz_sankey_id", choices = c("(no Sankeys found)" = ""))
        return()
      }
      labels <- sprintf("%s (%d cols, %s)", sankeys$title, sankeys$num_columns,
                        ifelse(sankeys$is_template, "template", "generated"))
      cur_sky <- isolate(input$viz_sankey_id)
      target_sky <- if (is_new_upload) {
        newest_row$sankey_id
      } else if (!is.null(cur_sky) && cur_sky %in% sankeys$sankey_id) {
        cur_sky
      } else {
        sankeys$sankey_id[1]
      }
      updateSelectInput(session, "viz_sankey_id", choices = setNames(sankeys$sankey_id, labels), selected = target_sky)

      cat(sprintf("    resolved: Category=%s | Domain=%s | Topic=%s | sankey_id=%s\n", target_cat, target_dom, target_top, target_sky))
      cat("--------------------------------------------------------\n")
    })

    # Explicit manual fallback: clears the taxonomy cache and forces a
    # genuinely fresh BigQuery pull.
    observeEvent(input$refresh, {
      cat("🔄 [Sankey Graph][DEBUG] Manual refresh requested - clearing taxonomy cache and re-querying BigQuery\n")
      api_manager$sankey_taxonomy_cache <- NULL
      api_manager$trigger_state_update_sankey()
      showNotification("Sankey list refreshed from BigQuery.", type = "message")
    })

    # ------------------------------------------------------------
    # Pull + render the selected Sankey
    # ------------------------------------------------------------
    observeEvent(input$view, {
      sky_id <- input$viz_sankey_id
      if (is.null(sky_id) || nchar(trimws(sky_id)) == 0) {
        showNotification("No Sankey selected.", type = "warning")
        return()
      }

      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Loading Sankey...") })

      cat("========================================================\n")
      cat("📥 [Sankey Graph][DEBUG] Visualizations tab: pulling Sankey from BigQuery\n")
      cat(sprintf("    sankey_id : %s\n", sky_id))
      t0 <- Sys.time()

      tryCatch({
        components <- api_manager$bq_get_sankey_components(sky_id)
        query_elapsed <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 2)

        if (nrow(components) == 0) {
          cat(sprintf("    result     : 0 rows returned in %ss - nothing to render\n", query_elapsed))
          cat("========================================================\n")
          output$status <- renderUI({
            tags$div(class = "status-warning", tags$i(class = "fa fa-exclamation-triangle"), " No rows found for this Sankey ID.")
          })
          output$sankey_output <- renderUI({ tags$div() })
          return()
        }

        node_count <- sum(components$row_kind == "node")
        link_count <- sum(components$row_kind == "link")

        cat(sprintf("    result     : %d row(s) returned in %ss (%d nodes, %d links)\n", nrow(components), query_elapsed, node_count, link_count))
        cat(sprintf("    title      : %s | num_columns: %s | num_initial_rows: %s\n", components$title[1], components$num_columns[1], components$num_initial_rows[1]))
        cat(sprintf("    category/domain/topic : %s / %s / %s\n", components$category[1], components$domain[1], components$topic[1]))

        node_refs <- components$component_ref[components$row_kind == "node"]
        orphan_links <- components[components$row_kind == "link" &
                                    (!(components$source_ref %in% node_refs) | !(components$target_ref %in% node_refs)), ]
        if (nrow(orphan_links) > 0) {
          cat(sprintf("    ⚠️  WARNING: %d link(s) reference a component_ref with no matching node - they will be silently skipped by d3-sankey\n", nrow(orphan_links)))
        }
        cat("========================================================\n")

        render_t0 <- Sys.time()
        rendered <- render_sankey(components)
        render_elapsed <- round(as.numeric(difftime(Sys.time(), render_t0, units = "secs")), 3)
        cat(sprintf("🎨 [Sankey Graph][DEBUG] render_sankey() completed in %ss\n", render_elapsed))

        export_title <- if (has_real_value(components$title[1])) components$title[1] else "sankey_diagram"
        output$sankey_output <- renderUI({ export_capture_wrapper(session$ns, rendered, export_title) })
        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Rendered %d node(s) and %d link(s)", node_count, link_count))
        })

      }, error = function(e) {
        cat(sprintf("❌ [Sankey Graph][DEBUG] Visualization failed: %s\n", e$message))
        cat("========================================================\n")
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        output$sankey_output <- renderUI({ tags$div() })
      })
    })

    output$status <- renderUI({ tags$div() })
    output$sankey_output <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
