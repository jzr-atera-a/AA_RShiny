# modules/edit_kg/server.R

edit_kg_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    current_graph <- reactiveVal(NULL)   # list(category, domain, topic, graph_title, graph_id, entities, relationships)
    pending_entity_delta <- reactiveVal(NULL)
    pending_relationship_delta <- reactiveVal(NULL)
    pending_cascade_deletes <- reactiveVal(character(0))  # relationship_ids implied by entity deletes

    # ------------------------------------------------------------
    # Category -> Domain -> Topic -> Graph Version cascade
    # (selecting EXISTING graphs only, no "add new" here)
    # ------------------------------------------------------------
    edit_taxonomy <- reactive({
      api_manager$state_trigger_kg()
      if (!api_manager$bq_authenticated) return(api_manager$empty_kg_taxonomy())
      tryCatch(api_manager$bq_get_kg_taxonomy(), error = function(e) api_manager$empty_kg_taxonomy())
    })

    observeEvent(edit_taxonomy(), {
      tax <- edit_taxonomy()
      categories <- sort(unique(tax$category[nchar(trimws(tax$category)) > 0]))
      if (length(categories) == 0) {
        updateSelectInput(session, "edit_category", choices = c("(no categories yet)" = ""))
      } else {
        current <- isolate(input$edit_category)
        selected <- if (!is.null(current) && current %in% categories) current else categories[1]
        updateSelectInput(session, "edit_category", choices = setNames(categories, categories), selected = selected)
      }
    }, ignoreNULL = FALSE)

    observeEvent(input$edit_category, {
      tax <- edit_taxonomy()
      if (is.null(input$edit_category) || input$edit_category == "") {
        updateSelectInput(session, "edit_domain", choices = c("(select a category first)" = ""))
        return()
      }
      domains <- sort(unique(tax$domain[tax$category == input$edit_category & nchar(trimws(tax$domain)) > 0]))
      if (length(domains) == 0) {
        updateSelectInput(session, "edit_domain", choices = c("(no domains found)" = ""))
      } else {
        updateSelectInput(session, "edit_domain", choices = setNames(domains, domains))
      }
    }, ignoreInit = TRUE)

    observeEvent(input$edit_domain, {
      tax <- edit_taxonomy()
      if (is.null(input$edit_category) || is.null(input$edit_domain) ||
          input$edit_category == "" || input$edit_domain == "") {
        updateSelectInput(session, "edit_topic", choices = c("(select a domain first)" = ""))
        return()
      }
      topics <- sort(unique(tax$topic[tax$category == input$edit_category &
                                       tax$domain == input$edit_domain &
                                       nchar(trimws(tax$topic)) > 0]))
      if (length(topics) == 0) {
        updateSelectInput(session, "edit_topic", choices = c("(no topics found)" = ""))
      } else {
        updateSelectInput(session, "edit_topic", choices = setNames(topics, topics))
      }
    }, ignoreInit = TRUE)

    observeEvent(input$edit_topic, {
      if (!api_manager$bq_authenticated || is.null(input$edit_category) || is.null(input$edit_domain) ||
          is.null(input$edit_topic) || input$edit_category == "" || input$edit_domain == "" ||
          input$edit_topic == "") {
        updateSelectInput(session, "edit_graph_id", choices = c("(select a topic first)" = ""))
        return()
      }

      tryCatch({
        graphs <- api_manager$bq_get_graph_ids_for_topic(input$edit_category, input$edit_domain, input$edit_topic)
        if (nrow(graphs) == 0) {
          updateSelectInput(session, "edit_graph_id", choices = c("(no graphs found)" = ""))
        } else {
          labels <- sprintf("%s (%s)", graphs$graph_title, graphs$graph_id)
          updateSelectInput(session, "edit_graph_id", choices = setNames(graphs$graph_id, labels))
        }
      }, error = function(e) {
        updateSelectInput(session, "edit_graph_id", choices = c("(error loading)" = ""))
      })
    }, ignoreInit = TRUE)

    # ------------------------------------------------------------
    # Load current graph state
    # ------------------------------------------------------------
    observeEvent(input$load_graph, {
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      if (is.null(input$edit_graph_id) || input$edit_graph_id == "") {
        showNotification("Please select a graph version to load!", type = "warning")
        return()
      }

      output$load_status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Loading current graph...")
      })

      tryCatch({
        state <- api_manager$get_current_graph_state(input$edit_graph_id)
        state$graph_id <- input$edit_graph_id
        current_graph(state)
        pending_entity_delta(NULL)
        pending_relationship_delta(NULL)
        pending_cascade_deletes(character(0))

        output$current_graph_outline <- renderUI({
          tags$div(class = "viz-card",
                   tags$div(class = "chapter-title", tags$i(class = "fa fa-project-diagram"), " ", state$graph_title),
                   tags$pre(style = "white-space: pre-wrap; font-family: 'Courier New', monospace; font-size: 0.85em;",
                            serialize_graph_for_prompt(state$entities, state$relationships, max_words_per_item = 30)))
        })

        output$load_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Loaded %d entit(y/ies), %d relationship(s) for '%s'",
                           nrow(state$entities), nrow(state$relationships), state$graph_title))
        })

        showNotification("✓ Graph loaded!", type = "message")

      }, error = function(e) {
        output$load_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    # ------------------------------------------------------------
    # Request an edit delta from Claude
    # ------------------------------------------------------------
    observeEvent(input$request_edit, {

      if (!api_manager$claude_authenticated) {
        showNotification("Please configure Claude API credentials first!", type = "error")
        return()
      }
      if (is.null(current_graph())) {
        showNotification("Please load the current graph first!", type = "warning")
        return()
      }
      if (nchar(trimws(input$edit_request)) == 0) {
        showNotification("Please describe what should change!", type = "warning")
        return()
      }

      state <- current_graph()
      include_latex <- identical(input$include_latex, "yes")
      words_per_item <- input$words_per_item %||% 30
      expected_changes <- input$expected_changes %||% 5

      dynamic_max_tokens <- estimate_kg_max_tokens(
        max_entities = expected_changes, max_relationships = expected_changes,
        words_per_entity = words_per_item, words_per_relationship = words_per_item,
        include_latex = include_latex
      )

      next_entity_id_start <- next_available_entity_id_num(state$entities)
      next_relationship_id_start <- next_available_relationship_id_num(state$relationships)
      current_graph_text <- serialize_graph_for_prompt(state$entities, state$relationships, max_words_per_item = 60)

      shinyjs::show("loading_spinner")
      output$raw_delta_text <- renderText({ "" })
      pending_entity_delta(NULL)
      pending_relationship_delta(NULL)
      pending_cascade_deletes(character(0))

      progress_msg <- reactiveVal("Building prompt...")
      output$edit_status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " ", progress_msg())
      })

      prompt <- generate_kg_edit_prompt(
        category = state$category, domain = state$domain, topic = state$topic, graph_title = state$graph_title,
        current_graph_text = current_graph_text, edit_request = trimws(input$edit_request),
        next_entity_id_start = next_entity_id_start, next_relationship_id_start = next_relationship_id_start,
        include_latex = include_latex, words_per_entity = words_per_item, words_per_relationship = words_per_item
      )

      tryCatch({
        progress_msg(sprintf("Sending edit request (budgeted ~%d tokens)...", dynamic_max_tokens))

        response_text <- api_manager$call_claude(
          prompt = prompt, max_tokens = dynamic_max_tokens,
          progress_callback = function(msg) progress_msg(msg)
        )

        output$raw_delta_text <- renderText({ response_text })

        delta <- parse_kg_delta_text(response_text)
        entity_delta <- delta$entity_delta
        relationship_delta <- delta$relationship_delta

        existing_entity_ids <- state$entities$entity_id
        existing_relationship_ids <- state$relationships$relationship_id

        e_creates <- entity_delta[entity_delta$change_type == "create", ]
        e_updates <- entity_delta[entity_delta$change_type == "update", ]
        e_deletes <- entity_delta[entity_delta$change_type == "delete", ]
        r_creates <- relationship_delta[relationship_delta$change_type == "create", ]
        r_updates <- relationship_delta[relationship_delta$change_type == "update", ]
        r_deletes <- relationship_delta[relationship_delta$change_type == "delete", ]

        problems <- c()
        if (any(e_creates$entity_id %in% existing_entity_ids)) {
          problems <- c(problems, sprintf("CREATE entity reused an existing entity_id: %s",
                                          paste(intersect(e_creates$entity_id, existing_entity_ids), collapse = ", ")))
        }
        bad <- setdiff(e_updates$entity_id, existing_entity_ids)
        if (length(bad) > 0) problems <- c(problems, sprintf("UPDATE entity referenced unknown entity_id(s): %s", paste(bad, collapse = ", ")))
        bad <- setdiff(e_deletes$entity_id, existing_entity_ids)
        if (length(bad) > 0) problems <- c(problems, sprintf("DELETE entity referenced unknown entity_id(s): %s", paste(bad, collapse = ", ")))

        if (any(r_creates$relationship_id %in% existing_relationship_ids)) {
          problems <- c(problems, sprintf("CREATE relationship reused an existing relationship_id: %s",
                                          paste(intersect(r_creates$relationship_id, existing_relationship_ids), collapse = ", ")))
        }
        bad <- setdiff(r_updates$relationship_id, existing_relationship_ids)
        if (length(bad) > 0) problems <- c(problems, sprintf("UPDATE relationship referenced unknown relationship_id(s): %s", paste(bad, collapse = ", ")))
        bad <- setdiff(r_deletes$relationship_id, existing_relationship_ids)
        if (length(bad) > 0) problems <- c(problems, sprintf("DELETE relationship referenced unknown relationship_id(s): %s", paste(bad, collapse = ", ")))

        # ---- Compute relationship cascade for deleted entities (app-side, not Claude) ----
        cascade_ids <- character(0)
        if (nrow(e_deletes) > 0) {
          cascade_ids <- compute_relationship_cascade_delete(state$relationships, e_deletes$entity_id)
        }
        implied_extra <- setdiff(cascade_ids, r_deletes$relationship_id)

        pending_entity_delta(entity_delta)
        pending_relationship_delta(relationship_delta)
        pending_cascade_deletes(implied_extra)

        output$delta_preview <- renderUI({
          render_kg_delta_preview(entity_delta, relationship_delta, implied_extra, state$entities, state$relationships)
        })

        if (length(problems) > 0) {
          output$edit_status <- renderUI({
            tags$div(class = "status-warning", tags$i(class = "fa fa-exclamation-triangle"),
                     " Claude's response has issues - review carefully before applying:",
                     tags$ul(lapply(problems, tags$li)))
          })
        } else {
          output$edit_status <- renderUI({
            tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                     sprintf(" Delta received: %d/%d/%d entity create/update/delete, %d/%d/%d relationship create/update/delete (+%d cascade-implied). Review below, then Apply.",
                             nrow(e_creates), nrow(e_updates), nrow(e_deletes),
                             nrow(r_creates), nrow(r_updates), nrow(r_deletes), length(implied_extra)))
          })
        }

        shinyjs::hide("loading_spinner")
        showNotification("✓ Edit delta received - review before applying.", type = "message")

      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        output$edit_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 15)
      })
    })

    # ------------------------------------------------------------
    # Apply the reviewed delta (+ cascade deletes) to BigQuery
    # ------------------------------------------------------------
    observeEvent(input$apply_changes, {

      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      if (is.null(pending_entity_delta()) || is.null(current_graph())) {
        showNotification("No pending changes to apply. Request an edit first.", type = "warning")
        return()
      }

      output$apply_status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Applying changes...")
      })

      tryCatch({
        state <- current_graph()
        entity_delta <- pending_entity_delta()
        relationship_delta <- pending_relationship_delta()
        cascade_extra <- pending_cascade_deletes()

        rows <- list()
        sort_ctr <- 0

        if (nrow(entity_delta) > 0) {
          for (i in seq_len(nrow(entity_delta))) {
            d <- entity_delta[i, ]
            sort_ctr <- sort_ctr + 1
            rows[[length(rows) + 1]] <- data.frame(
              change_type = d$change_type, row_kind = "entity",
              entity_id = d$entity_id,
              entity_label = ifelse(d$change_type == "delete", "", ifelse(is.na(d$entity_label), "", d$entity_label)),
              entity_type = ifelse(d$change_type == "delete", "", ifelse(is.na(d$entity_type), "", d$entity_type)),
              entity_description = ifelse(d$change_type == "delete", "", ifelse(is.na(d$entity_description), "", d$entity_description)),
              relationship_id = "", source_entity_id = "", predicate = "", target_entity_id = "", relationship_description = "",
              sort_order = sort_ctr, stringsAsFactors = FALSE
            )
          }
        }

        if (nrow(relationship_delta) > 0) {
          for (i in seq_len(nrow(relationship_delta))) {
            d <- relationship_delta[i, ]
            sort_ctr <- sort_ctr + 1
            rows[[length(rows) + 1]] <- data.frame(
              change_type = d$change_type, row_kind = "relationship",
              entity_id = "", entity_label = "", entity_type = "", entity_description = "",
              relationship_id = d$relationship_id,
              source_entity_id = ifelse(d$change_type == "delete", "", ifelse(is.na(d$source_entity_id), "", d$source_entity_id)),
              predicate = ifelse(d$change_type == "delete", "", ifelse(is.na(d$predicate), "", d$predicate)),
              target_entity_id = ifelse(d$change_type == "delete", "", ifelse(is.na(d$target_entity_id), "", d$target_entity_id)),
              relationship_description = ifelse(d$change_type == "delete", "", ifelse(is.na(d$relationship_description), "", d$relationship_description)),
              sort_order = sort_ctr, stringsAsFactors = FALSE
            )
          }
        }

        if (length(cascade_extra) > 0) {
          for (rid in cascade_extra) {
            sort_ctr <- sort_ctr + 1
            rows[[length(rows) + 1]] <- data.frame(
              change_type = "delete", row_kind = "relationship",
              entity_id = "", entity_label = "", entity_type = "", entity_description = "",
              relationship_id = rid, source_entity_id = "", predicate = "", target_entity_id = "", relationship_description = "",
              sort_order = sort_ctr, stringsAsFactors = FALSE
            )
          }
        }

        upload_df <- do.call(rbind, rows)
        upload_df$category <- state$category
        upload_df$domain <- state$domain
        upload_df$topic <- state$topic
        upload_df$graph_id <- state$graph_id
        upload_df$graph_title <- state$graph_title

        rows_uploaded <- api_manager$bq_insert_kg(upload_df, source = "claude")
        api_manager$trigger_state_update_kg()

        pending_entity_delta(NULL)
        pending_relationship_delta(NULL)
        pending_cascade_deletes(character(0))

        output$apply_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Applied %d row(s) to BigQuery. Reload the graph above or check the Visualize tabs to see the result.",
                           rows_uploaded))
        })

        showNotification(sprintf("✓ Applied %d change(s)!", rows_uploaded), type = "message")

      }, error = function(e) {
        output$apply_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$load_status <- renderUI({ tags$div() })
    output$current_graph_outline <- renderUI({ tags$div() })
    output$edit_status <- renderUI({ tags$div() })
    output$raw_delta_text <- renderText({ "" })
    output$delta_preview <- renderUI({ tags$div(class = "status-info", "Request an edit above to see a preview here.") })
    output$apply_status <- renderUI({ tags$div() })

    session$onSessionEnded(function() {})
  })
}

# Renders a color-coded preview of a parsed delta: entity/relationship
# creates, updates, deletes, and cascade-implied relationship deletes
# shown separately so the user can see exactly what an entity DELETE
# will actually remove before committing.
render_kg_delta_preview <- function(entity_delta, relationship_delta, cascade_extra, current_entities, current_relationships) {

  entity_label_for <- function(entity_id) {
    idx <- which(current_entities$entity_id == entity_id)
    if (length(idx) > 0) current_entities$entity_label[idx[1]] else "(new entity)"
  }
  relationship_label_for <- function(relationship_id) {
    idx <- which(current_relationships$relationship_id == relationship_id)
    if (length(idx) > 0) sprintf("%s --[%s]--> %s", current_relationships$source_entity_id[idx[1]],
                                 current_relationships$predicate[idx[1]], current_relationships$target_entity_id[idx[1]])
    else "(unknown)"
  }

  section <- function(title, icon_name, color, lines) {
    if (length(lines) == 0) return(NULL)
    tags$div(style = sprintf("margin-bottom: 12px; padding: 10px; border-left: 4px solid %s; background: #f8f9fa; border-radius: 6px;", color),
             tags$strong(tags$i(class = paste0("fa fa-", icon_name)), " ", title),
             tags$ul(lapply(lines, tags$li)))
  }

  e_creates <- entity_delta[entity_delta$change_type == "create", ]
  e_updates <- entity_delta[entity_delta$change_type == "update", ]
  e_deletes <- entity_delta[entity_delta$change_type == "delete", ]
  r_creates <- relationship_delta[relationship_delta$change_type == "create", ]
  r_updates <- relationship_delta[relationship_delta$change_type == "update", ]
  r_deletes <- relationship_delta[relationship_delta$change_type == "delete", ]

  tagList(
    section("CREATE Entity", "plus-circle", "#27ae60", sprintf("%s: %s", e_creates$entity_id, e_creates$entity_label)),
    section("UPDATE Entity", "pencil-alt", "#f39c12", sprintf("%s: %s", e_updates$entity_id, e_updates$entity_label)),
    section("DELETE Entity", "trash", "#e74c3c", sprintf("%s: %s", e_deletes$entity_id, sapply(e_deletes$entity_id, entity_label_for))),
    section("CREATE Relationship", "plus-circle", "#27ae60",
            sprintf("%s: %s --[%s]--> %s", r_creates$relationship_id, r_creates$source_entity_id, r_creates$predicate, r_creates$target_entity_id)),
    section("UPDATE Relationship", "pencil-alt", "#f39c12",
            sprintf("%s: %s --[%s]--> %s", r_updates$relationship_id, r_updates$source_entity_id, r_updates$predicate, r_updates$target_entity_id)),
    section("DELETE Relationship (explicitly requested)", "trash", "#e74c3c",
            sprintf("%s: %s", r_deletes$relationship_id, sapply(r_deletes$relationship_id, relationship_label_for))),
    section("DELETE Relationship (cascade - touched a deleted entity)", "sitemap", "#c0392b",
            sprintf("%s: %s", cascade_extra, sapply(cascade_extra, relationship_label_for)))
  )
}
