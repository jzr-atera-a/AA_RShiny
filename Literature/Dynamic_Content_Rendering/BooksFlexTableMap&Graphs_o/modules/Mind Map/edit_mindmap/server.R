# modules/edit_mindmap/server.R

edit_mindmap_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    current_tree <- reactiveVal(NULL)   # list(category, domain, topic, map_title, map_id, nodes)
    pending_delta <- reactiveVal(NULL)  # data.frame from parse_mindmap_delta_text()
    pending_cascade_deletes <- reactiveVal(character(0))  # extra node_ids implied by cascade

    # ------------------------------------------------------------
    # Category -> Domain -> Topic -> Map Version cascade
    # (selecting EXISTING maps only, no "add new" here)
    # ------------------------------------------------------------
    edit_taxonomy <- reactive({
      api_manager$state_trigger_mindmap()
      if (!api_manager$bq_authenticated) return(api_manager$empty_mindmap_taxonomy())
      tryCatch(api_manager$bq_get_mindmap_taxonomy(), error = function(e) api_manager$empty_mindmap_taxonomy())
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
        updateSelectInput(session, "edit_map_id", choices = c("(select a topic first)" = ""))
        return()
      }

      tryCatch({
        maps <- api_manager$bq_get_map_ids_for_topic(input$edit_category, input$edit_domain, input$edit_topic)
        if (nrow(maps) == 0) {
          updateSelectInput(session, "edit_map_id", choices = c("(no maps found)" = ""))
        } else {
          labels <- sprintf("%s (%s)", maps$map_title, maps$map_id)
          updateSelectInput(session, "edit_map_id", choices = setNames(maps$map_id, labels))
        }
      }, error = function(e) {
        updateSelectInput(session, "edit_map_id", choices = c("(error loading)" = ""))
      })
    }, ignoreInit = TRUE)

    # ------------------------------------------------------------
    # Load current tree state
    # ------------------------------------------------------------
    observeEvent(input$load_tree, {
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      if (is.null(input$edit_map_id) || input$edit_map_id == "") {
        showNotification("Please select a map version to load!", type = "warning")
        return()
      }

      output$load_status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Loading current tree...")
      })

      tryCatch({
        state <- api_manager$get_current_tree_state(input$edit_map_id)
        state$map_id <- input$edit_map_id
        current_tree(state)
        pending_delta(NULL)
        pending_cascade_deletes(character(0))

        output$current_tree_outline <- renderUI({
          tags$div(class = "viz-card",
                   tags$div(class = "chapter-title", tags$i(class = "fa fa-sitemap"), " ", state$map_title),
                   tags$pre(style = "white-space: pre-wrap; font-family: 'Courier New', monospace; font-size: 0.85em;",
                            serialize_tree_for_prompt(state$nodes, max_words_per_node = 30)))
        })

        output$load_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Loaded %d node(s) for '%s'", nrow(state$nodes), state$map_title))
        })

        showNotification("✓ Tree loaded!", type = "message")

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
      if (is.null(current_tree())) {
        showNotification("Please load the current tree first!", type = "warning")
        return()
      }
      if (nchar(trimws(input$edit_request)) == 0) {
        showNotification("Please describe what should change!", type = "warning")
        return()
      }

      state <- current_tree()
      include_latex <- identical(input$include_latex, "yes")
      words_per_node <- input$words_per_node %||% 40
      expected_changes <- input$expected_changes %||% 5

      dynamic_max_tokens <- estimate_mindmap_max_tokens(
        max_nodes = expected_changes, words_per_node = words_per_node, include_latex = include_latex
      )

      next_id_start <- next_available_node_id_num(state$nodes)
      current_tree_text <- serialize_tree_for_prompt(state$nodes, max_words_per_node = 60)

      shinyjs::show("loading_spinner")
      output$raw_delta_text <- renderText({ "" })
      pending_delta(NULL)
      pending_cascade_deletes(character(0))

      progress_msg <- reactiveVal("Building prompt...")
      output$edit_status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " ", progress_msg())
      })

      prompt <- generate_mindmap_edit_prompt(
        category = state$category, domain = state$domain, topic = state$topic, map_title = state$map_title,
        current_tree_text = current_tree_text, edit_request = trimws(input$edit_request),
        next_id_start = next_id_start, include_latex = include_latex, words_per_node = words_per_node
      )

      tryCatch({
        progress_msg(sprintf("Sending edit request (budgeted ~%d tokens)...", dynamic_max_tokens))

        response_text <- api_manager$call_claude(
          prompt = prompt, max_tokens = dynamic_max_tokens,
          progress_callback = function(msg) progress_msg(msg)
        )

        output$raw_delta_text <- renderText({ response_text })

        delta_df <- parse_mindmap_delta_text(response_text)

        # ---- Validate delta against the current tree ----
        existing_ids <- state$nodes$node_id
        creates <- delta_df[delta_df$change_type == "create", ]
        updates <- delta_df[delta_df$change_type == "update", ]
        deletes <- delta_df[delta_df$change_type == "delete", ]

        problems <- c()
        if (any(creates$node_id %in% existing_ids)) {
          problems <- c(problems, sprintf("CREATE reused an existing node_id: %s",
                                          paste(intersect(creates$node_id, existing_ids), collapse = ", ")))
        }
        bad_updates <- setdiff(updates$node_id, existing_ids)
        if (length(bad_updates) > 0) {
          problems <- c(problems, sprintf("UPDATE referenced unknown node_id(s): %s", paste(bad_updates, collapse = ", ")))
        }
        bad_deletes <- setdiff(deletes$node_id, existing_ids)
        if (length(bad_deletes) > 0) {
          problems <- c(problems, sprintf("DELETE referenced unknown node_id(s): %s", paste(bad_deletes, collapse = ", ")))
        }

        # ---- Compute cascade deletes (app-side, not Claude) ----
        all_cascade <- character(0)
        if (nrow(deletes) > 0) {
          for (nid in deletes$node_id) {
            if (nid %in% existing_ids) {
              all_cascade <- union(all_cascade, compute_cascade_delete(state$nodes, nid))
            }
          }
        }
        implied_extra <- setdiff(all_cascade, deletes$node_id)

        pending_delta(delta_df)
        pending_cascade_deletes(implied_extra)

        output$delta_preview <- renderUI({
          render_delta_preview(delta_df, implied_extra, state$nodes)
        })

        if (length(problems) > 0) {
          output$edit_status <- renderUI({
            tags$div(class = "status-warning",
                     tags$i(class = "fa fa-exclamation-triangle"),
                     " Claude's response has issues - review carefully before applying:",
                     tags$ul(lapply(problems, tags$li)))
          })
        } else {
          output$edit_status <- renderUI({
            tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                     sprintf(" Delta received: %d create, %d update, %d delete (+%d cascade-implied). Review below, then Apply.",
                             nrow(creates), nrow(updates), nrow(deletes), length(implied_extra)))
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
      if (is.null(pending_delta()) || is.null(current_tree())) {
        showNotification("No pending changes to apply. Request an edit first.", type = "warning")
        return()
      }

      output$apply_status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Applying changes...")
      })

      tryCatch({
        state <- current_tree()
        delta_df <- pending_delta()
        cascade_extra <- pending_cascade_deletes()

        rows <- list()

        for (i in seq_len(nrow(delta_df))) {
          d <- delta_df[i, ]
          rows[[length(rows) + 1]] <- data.frame(
            change_type = d$change_type,
            node_id = d$node_id,
            node_label = ifelse(d$change_type == "delete", "", ifelse(is.na(d$node_label), "", d$node_label)),
            node_content = ifelse(d$change_type == "delete", "", ifelse(is.na(d$node_content), "", d$node_content)),
            parent_node_id = ifelse(d$change_type == "delete", "", ifelse(is.na(d$parent_node_id), "", d$parent_node_id)),
            cross_links = ifelse(d$change_type == "delete", "", ifelse(is.na(d$cross_links), "", d$cross_links)),
            sort_order = i,
            stringsAsFactors = FALSE
          )
        }

        # Cascade-implied deletes not already explicitly listed by Claude
        if (length(cascade_extra) > 0) {
          for (j in seq_along(cascade_extra)) {
            rows[[length(rows) + 1]] <- data.frame(
              change_type = "delete", node_id = cascade_extra[j],
              node_label = "", node_content = "", parent_node_id = "", cross_links = "",
              sort_order = nrow(delta_df) + j, stringsAsFactors = FALSE
            )
          }
        }

        upload_df <- do.call(rbind, rows)
        upload_df$category <- state$category
        upload_df$domain <- state$domain
        upload_df$topic <- state$topic
        upload_df$map_id <- state$map_id
        upload_df$map_title <- state$map_title

        rows_uploaded <- api_manager$bq_insert_mindmap(upload_df, source = "claude")
        api_manager$trigger_state_update_mindmap()

        pending_delta(NULL)
        pending_cascade_deletes(character(0))

        output$apply_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Applied %d row(s) to BigQuery. Reload the tree above or check Visualize Mind Map to see the result.",
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
    output$current_tree_outline <- renderUI({ tags$div() })
    output$edit_status <- renderUI({ tags$div() })
    output$raw_delta_text <- renderText({ "" })
    output$delta_preview <- renderUI({ tags$div(class = "status-info", "Request an edit above to see a preview here.") })
    output$apply_status <- renderUI({ tags$div() })

    session$onSessionEnded(function() {})
  })
}

# Renders a color-coded preview of a parsed delta: creates, updates,
# deletes, and cascade-implied deletes shown separately so the user can
# see exactly what a DELETE will actually remove before committing.
render_delta_preview <- function(delta_df, cascade_extra, current_nodes) {
  creates <- delta_df[delta_df$change_type == "create", ]
  updates <- delta_df[delta_df$change_type == "update", ]
  deletes <- delta_df[delta_df$change_type == "delete", ]

  label_for <- function(node_id) {
    match_idx <- which(current_nodes$node_id == node_id)
    if (length(match_idx) > 0) current_nodes$node_label[match_idx[1]] else "(new node)"
  }

  section <- function(title, icon_name, color, ids, labels_source = NULL) {
    if (length(ids) == 0) return(NULL)
    tags$div(style = sprintf("margin-bottom: 12px; padding: 10px; border-left: 4px solid %s; background: #f8f9fa; border-radius: 6px;", color),
             tags$strong(tags$i(class = paste0("fa fa-", icon_name)), " ", title),
             tags$ul(lapply(ids, function(x) tags$li(x)))
    )
  }

  tagList(
    if (nrow(creates) > 0) section("CREATE", "plus-circle", "#27ae60",
                                    sprintf("%s: %s", creates$node_id, creates$node_label)),
    if (nrow(updates) > 0) section("UPDATE", "pencil-alt", "#f39c12",
                                    sprintf("%s: %s", updates$node_id, updates$node_label)),
    if (nrow(deletes) > 0) section("DELETE (explicitly requested)", "trash", "#e74c3c",
                                    sprintf("%s: %s", deletes$node_id, sapply(deletes$node_id, label_for))),
    if (length(cascade_extra) > 0) section("DELETE (cascade - descendants of the above)", "sitemap", "#c0392b",
                                            sprintf("%s: %s", cascade_extra, sapply(cascade_extra, label_for)))
  )
}
