# modules/generate_mindmap/server.R

generate_mindmap_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    cat_dom_topic <- setup_category_domain_topic_cascade(input, output, session, api_manager)

    observeEvent(input$generate, {

      if (!api_manager$claude_authenticated) {
        showNotification("Please configure and save Claude API credentials first!", type = "error", duration = 10)
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please configure Claude API in the Claude API Config tab first!")
        })
        return()
      }

      cdt <- cat_dom_topic()
      if (nchar(cdt$category) == 0 || nchar(cdt$domain) == 0 || nchar(cdt$topic) == 0) {
        showNotification("Please select or enter Category, Domain, and Topic!", type = "error")
        return()
      }

      if (nchar(trimws(input$request_description)) == 0) {
        showNotification("Please describe what the mind map should cover!", type = "error")
        return()
      }

      map_title <- if (nchar(trimws(input$map_title)) > 0) trimws(input$map_title) else cdt$topic

      include_latex <- identical(input$include_latex, "yes")
      words_per_node <- input$words_per_node %||% 40
      max_nodes <- input$max_nodes %||% 12
      max_depth <- input$max_depth %||% 3
      max_root_children <- input$max_root_children %||% 6
      max_children_per_node <- input$max_children_per_node %||% 5

      dynamic_max_tokens <- estimate_mindmap_max_tokens(
        max_nodes = max_nodes, words_per_node = words_per_node, include_latex = include_latex
      )

      shinyjs::show("loading_spinner")
      updateTextAreaInput(session, "generated_text_edit", value = "")

      progress_msg <- reactiveVal("Initializing...")
      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " ", progress_msg())
      })

      prompt <- tryCatch({
        generate_mindmap_prompt(
          category = cdt$category, domain = cdt$domain, topic = cdt$topic, map_title = map_title,
          request_description = trimws(input$request_description),
          include_latex = include_latex, words_per_node = words_per_node,
          max_nodes = max_nodes, max_depth = max_depth,
          max_root_children = max_root_children, max_children_per_node = max_children_per_node
        )
      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                   " Failed to build prompt: ", e$message)
        })
        NULL
      })

      if (is.null(prompt)) return()

      tryCatch({
        progress_msg("Building prompt...")
        Sys.sleep(0.2)
        progress_msg(sprintf("Sending request (budgeted ~%d tokens for ~%d nodes, %d words/node)...",
                             dynamic_max_tokens, max_nodes, words_per_node))

        response_text <- api_manager$call_claude(
          prompt = prompt, max_tokens = dynamic_max_tokens,
          progress_callback = function(msg) progress_msg(msg)
        )

        was_truncated <- identical(attr(response_text, "claude_stop_reason"), "max_tokens")

        updateTextAreaInput(session, "generated_text_edit", value = response_text)

        output$preview_html <- renderUI({
          render_mindmap_preview(response_text, max_root_children = max_root_children,
                                 max_children_per_node = max_children_per_node)
        })

        if (was_truncated) {
          output$status <- renderUI({
            tags$div(class = "status-error",
                     tags$i(class = "fa fa-exclamation-triangle"),
                     sprintf(" ⚠️ Response was CUT OFF - Claude hit the %d-token budget mid-generation. ",
                             dynamic_max_tokens),
                     "The last node in the text below is very likely incomplete and will be dropped ",
                     "automatically before upload (you'll see which one). ",
                     tags$strong("To get the full tree: "), "increase 'Target Total Nodes' and/or ",
                     "'Max Words per Node' to raise the budget, then regenerate - or just remove a few ",
                     "of the least important nodes by hand in the box below and upload what's there.")
          })
          showNotification("⚠️ Response was cut off by the token limit - see details above.",
                           type = "warning", duration = 12)
        } else {
          output$status <- renderUI({
            tags$div(class = "status-success",
                     tags$i(class = "fa fa-check-circle"),
                     sprintf(" ✓ Mind map generated! (%d characters)", nchar(response_text)))
          })
          showNotification("✓ Mind map generated!", type = "message")
        }

        shinyjs::hide("loading_spinner")

      }, error = function(e) {
        shinyjs::hide("loading_spinner")

        error_message <- e$message
        suggestion <- ""
        if (grepl("timeout", error_message, ignore.case = TRUE)) {
          suggestion <- "💡 Try: Increase timeout in Claude API Config"
        } else if (grepl("schannel|close_notify|peer|connection", error_message, ignore.case = TRUE)) {
          suggestion <- "💡 Try: Run Network Diagnostics in Claude API Config, or a smaller node count first"
        } else if (grepl("401|authentication", error_message, ignore.case = TRUE)) {
          suggestion <- "💡 Try: Re-enter your API key in Claude API Config"
        }

        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Generation Failed", tags$br(),
                   tags$strong("Error: "), tags$small(error_message),
                   if (nchar(suggestion) > 0) tagList(tags$br(), tags$br(), tags$span(style = "color: #f39c12;", suggestion)) else NULL)
        })

        showNotification(paste("Error:", error_message), type = "error", duration = 15)
      })
    })

    # Re-parse whatever is CURRENTLY in the editable text box (which may
    # have been hand-edited since generation) and refresh the Structure
    # Preview - deliberately manual/explicit rather than auto-reactive
    # on every keystroke, so a mid-edit partial paste never flashes
    # confusing errors while the user is still typing.
    observeEvent(input$reparse_preview, {
      if (nchar(trimws(input$generated_text_edit)) == 0) {
        showNotification("Nothing to re-parse - the text box is empty.", type = "warning")
        return()
      }

      output$preview_html <- renderUI({
        render_mindmap_preview(
          input$generated_text_edit,
          max_root_children = input$max_root_children %||% 6,
          max_children_per_node = input$max_children_per_node %||% 5
        )
      })

      showNotification("✓ Preview refreshed from current text box content.", type = "message")
    })

    observeEvent(input$parse_and_upload, {

      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }

      if (nchar(trimws(input$generated_text_edit)) == 0) {
        showNotification("No mind map to upload. Generate first.", type = "warning")
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing and validating...")
      })

      tryCatch({
        parsed <- parse_mindmap_creation_text(input$generated_text_edit)

        # Auto-remove spurious empty/disconnected node blocks (e.g. a
        # stray trailing second "ROOT" node with no label/content/
        # children/cross-links) BEFORE validation, so an artifact the
        # user never asked for doesn't block an otherwise-good upload.
        pruned <- prune_empty_disconnected_nodes(parsed$nodes)
        parsed$nodes <- pruned$nodes

        validation <- validate_tree_structure(
          parsed$nodes,
          max_root_children = input$max_root_children %||% 6,
          max_children_per_node = input$max_children_per_node %||% 5
        )

        if (!validation$valid) {
          output$status <- renderUI({
            tagList(
              if (!is.null(parsed$truncated_node_id)) {
                tags$div(class = "status-warning",
                         tags$i(class = "fa fa-cut"),
                         sprintf(" Response appears TRUNCATED - node %s was incomplete (missing [parent_id]) and was dropped.",
                                 parsed$truncated_node_id))
              } else NULL,
              if (length(pruned$pruned_ids) > 0) {
                tags$div(class = "status-info",
                         tags$i(class = "fa fa-info-circle"),
                         sprintf(" Auto-removed %d empty/disconnected node(s) before validation: %s",
                                 length(pruned$pruned_ids), paste(pruned$pruned_ids, collapse = ", ")))
              } else NULL,
              tags$div(class = "status-error",
                       tags$i(class = "fa fa-times-circle"),
                       " The generated tree still has structural problems and was NOT uploaded:",
                       tags$ul(lapply(validation$issues, tags$li)))
            )
          })
          showNotification("Tree validation failed - see details above.", type = "error", duration = 10)
          return()
        }

        map_id <- generate_new_map_id(parsed$topic)

        upload_df <- parsed$nodes
        upload_df$change_type <- "create"
        upload_df$category <- parsed$category
        upload_df$domain <- parsed$domain
        upload_df$topic <- parsed$topic
        upload_df$map_id <- map_id
        upload_df$map_title <- parsed$map_title

        rows_uploaded <- api_manager$bq_insert(upload_df, source = "claude")
        api_manager$trigger_state_update()

        output$status <- renderUI({
          tagList(
            if (!is.null(parsed$truncated_node_id)) {
              tags$div(class = "status-warning",
                       tags$i(class = "fa fa-cut"),
                       sprintf(" Response appears TRUNCATED - node %s was incomplete (missing [parent_id]) and was dropped before upload. The uploaded map is missing this node.",
                               parsed$truncated_node_id))
            } else NULL,
            if (length(pruned$pruned_ids) > 0) {
              tags$div(class = "status-info",
                       tags$i(class = "fa fa-info-circle"),
                       sprintf(" Auto-removed %d empty/disconnected node(s) before upload: %s",
                               length(pruned$pruned_ids), paste(pruned$pruned_ids, collapse = ", ")))
            } else NULL,
            tags$div(class = "status-success",
                     tags$i(class = "fa fa-check-circle"),
                     sprintf(" Uploaded %d node(s) as a new map (map_id: %s). Check Visualize Mind Map to view it.",
                             rows_uploaded, map_id)),
            if (length(validation$warnings) > 0) {
              tags$div(class = "status-warning",
                       tags$i(class = "fa fa-exclamation-triangle"),
                       " Non-blocking warnings (uploaded anyway):",
                       tags$ul(lapply(validation$warnings, tags$li)))
            } else NULL
          )
        })

        showNotification(sprintf("✓ Uploaded %d node(s)!", rows_uploaded), type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$download <- downloadHandler(
      filename = function() {
        title_part <- if (nchar(trimws(input$map_title)) > 0) input$map_title else "mindmap"
        paste0(gsub("[^A-Za-z0-9]+", "_", title_part), "_", format(Sys.Date(), "%Y%m%d"), ".txt")
      },
      content = function(file) { writeLines(input$generated_text_edit %||% "", file) }
    )

    output$status <- renderUI({ tags$div() })
    output$preview_html <- renderUI({ tags$div(class = "status-info", "Generate a mind map above to see a preview here.") })

    session$onSessionEnded(function() {})
  })
}

# Compact outline preview shared style with the table app's card preview
render_mindmap_preview <- function(map_text, max_root_children = NULL, max_children_per_node = NULL) {
  parsed <- tryCatch(parse_mindmap_creation_text(map_text), error = function(e) NULL)

  if (is.null(parsed) || nrow(parsed$nodes) == 0) {
    return(tags$div(class = "status-warning", "Could not parse a preview - check the raw text format."))
  }

  pruned <- prune_empty_disconnected_nodes(parsed$nodes)
  parsed$nodes <- pruned$nodes

  validation <- validate_tree_structure(
    parsed$nodes, max_root_children = max_root_children, max_children_per_node = max_children_per_node
  )
  outline_text <- serialize_tree_for_prompt(parsed$nodes, max_words_per_node = 20)

  tagList(
    if (!is.null(parsed$truncated_node_id)) {
      tags$div(class = "status-warning",
               tags$i(class = "fa fa-cut"),
               sprintf(" Response appears TRUNCATED - node %s was incomplete (missing [parent_id]) and was dropped.",
                       parsed$truncated_node_id))
    } else NULL,
    tags$p(class = "flex-table-note",
           sprintf("Parsed %d node(s)%s. Category: %s | Domain: %s | Topic: %s",
                   nrow(parsed$nodes),
                   if (length(pruned$pruned_ids) > 0) sprintf(" (%d empty/disconnected node(s) auto-removed: %s)",
                                                              length(pruned$pruned_ids), paste(pruned$pruned_ids, collapse = ", ")) else "",
                   parsed$category, parsed$domain, parsed$topic)),
    if (!validation$valid) {
      tags$div(class = "status-error",
               tags$i(class = "fa fa-times-circle"),
               " Structural issues detected (upload will be BLOCKED until fixed): ",
               tags$ul(lapply(validation$issues, tags$li)))
    } else {
      tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " Tree structure looks valid.")
    },
    if (length(validation$warnings) > 0) {
      tags$div(class = "status-warning",
               tags$i(class = "fa fa-exclamation-triangle"),
               " Non-blocking warnings: ",
               tags$ul(lapply(validation$warnings, tags$li)))
    } else NULL,
    tags$div(class = "viz-card",
             tags$pre(style = "white-space: pre-wrap; font-family: 'Courier New', monospace; font-size: 0.85em;",
                      outline_text)),
    tags$script(HTML("if (typeof MathJax !== 'undefined') { MathJax.Hub.Queue(['Typeset', MathJax.Hub]); }"))
  )
}
