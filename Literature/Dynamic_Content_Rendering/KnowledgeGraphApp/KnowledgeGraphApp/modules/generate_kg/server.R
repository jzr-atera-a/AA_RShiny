# modules/generate_kg/server.R

generate_kg_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    cat_dom_topic <- setup_category_domain_topic_cascade(input, output, session, api_manager)

    observeEvent(input$generate, {

      if (!api_manager$claude_authenticated) {
        showNotification("Please configure and save Claude API credentials first!", type = "error", duration = 10)
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
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
        showNotification("Please describe what the knowledge graph should cover!", type = "error")
        return()
      }

      graph_title <- if (nchar(trimws(input$graph_title)) > 0) trimws(input$graph_title) else cdt$topic

      include_latex <- identical(input$include_latex, "yes")
      words_per_entity <- input$words_per_entity %||% 30
      words_per_relationship <- input$words_per_relationship %||% 25
      max_entities <- input$max_entities %||% 15
      max_relationships <- input$max_relationships %||% 20
      max_relationships_per_entity <- input$max_relationships_per_entity %||% 8

      dynamic_max_tokens <- estimate_kg_max_tokens(
        max_entities = max_entities, max_relationships = max_relationships,
        words_per_entity = words_per_entity, words_per_relationship = words_per_relationship,
        include_latex = include_latex
      )

      shinyjs::show("loading_spinner")
      updateTextAreaInput(session, "generated_text_edit", value = "")

      progress_msg <- reactiveVal("Initializing...")
      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " ", progress_msg())
      })

      prompt <- tryCatch({
        generate_kg_prompt(
          category = cdt$category, domain = cdt$domain, topic = cdt$topic, graph_title = graph_title,
          request_description = trimws(input$request_description),
          include_latex = include_latex, words_per_entity = words_per_entity,
          words_per_relationship = words_per_relationship, max_entities = max_entities,
          max_relationships = max_relationships, max_relationships_per_entity = max_relationships_per_entity
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
        progress_msg(sprintf("Sending request (budgeted ~%d tokens for ~%d entities, ~%d relationships)...",
                             dynamic_max_tokens, max_entities, max_relationships))

        response_text <- api_manager$call_claude(
          prompt = prompt, max_tokens = dynamic_max_tokens,
          progress_callback = function(msg) progress_msg(msg)
        )

        was_truncated <- identical(attr(response_text, "claude_stop_reason"), "max_tokens")

        updateTextAreaInput(session, "generated_text_edit", value = response_text)

        output$preview_html <- renderUI({
          render_kg_preview(response_text, max_relationships_per_entity = max_relationships_per_entity)
        })

        if (was_truncated) {
          output$status <- renderUI({
            tags$div(class = "status-error",
                     tags$i(class = "fa fa-exclamation-triangle"),
                     sprintf(" ⚠️ Response was CUT OFF - Claude hit the %d-token budget mid-generation. ",
                             dynamic_max_tokens),
                     "The last block in the text below is very likely incomplete and will be dropped ",
                     "automatically before upload. ",
                     tags$strong("To get the full graph: "), "increase the Target Total fields and/or ",
                     "words-per-description sliders to raise the budget, then regenerate - or edit the ",
                     "box below by hand and upload what's there.")
          })
          showNotification("⚠️ Response was cut off by the token limit - see details above.",
                           type = "warning", duration = 12)
        } else {
          output$status <- renderUI({
            tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                     sprintf(" ✓ Knowledge graph generated! (%d characters)", nchar(response_text)))
          })
          showNotification("✓ Knowledge graph generated!", type = "message")
        }

        shinyjs::hide("loading_spinner")

      }, error = function(e) {
        shinyjs::hide("loading_spinner")

        error_message <- e$message
        suggestion <- ""
        if (grepl("timeout", error_message, ignore.case = TRUE)) {
          suggestion <- "💡 Try: Increase timeout in Claude API Config"
        } else if (grepl("schannel|close_notify|peer|connection", error_message, ignore.case = TRUE)) {
          suggestion <- "💡 Try: Run Network Diagnostics in Claude API Config, or a smaller graph first"
        } else if (grepl("401|authentication", error_message, ignore.case = TRUE)) {
          suggestion <- "💡 Try: Re-enter your API key in Claude API Config"
        }

        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                   " Generation Failed", tags$br(),
                   tags$strong("Error: "), tags$small(error_message),
                   if (nchar(suggestion) > 0) tagList(tags$br(), tags$br(), tags$span(style = "color: #f39c12;", suggestion)) else NULL)
        })

        showNotification(paste("Error:", error_message), type = "error", duration = 15)
      })
    })

    observeEvent(input$reparse_preview, {
      if (nchar(trimws(input$generated_text_edit)) == 0) {
        showNotification("Nothing to re-parse - the text box is empty.", type = "warning")
        return()
      }

      output$preview_html <- renderUI({
        render_kg_preview(input$generated_text_edit,
                          max_relationships_per_entity = input$max_relationships_per_entity %||% 8)
      })

      showNotification("✓ Preview refreshed from current text box content.", type = "message")
    })

    observeEvent(input$parse_and_upload, {

      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      if (nchar(trimws(input$generated_text_edit)) == 0) {
        showNotification("No knowledge graph to upload. Generate first.", type = "warning")
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing and validating...")
      })

      tryCatch({
        parsed <- parse_kg_creation_text(input$generated_text_edit)

        pruned <- prune_empty_disconnected_entities(parsed$entities, parsed$relationships)
        parsed$entities <- pruned$entities

        validation <- validate_kg_structure(
          parsed$entities, parsed$relationships,
          max_relationships_per_entity = input$max_relationships_per_entity %||% 8
        )

        truncation_note <- if (!is.null(parsed$truncated_id)) {
          tags$div(class = "status-warning", tags$i(class = "fa fa-cut"),
                   sprintf(" Response appears TRUNCATED - block %s was incomplete and was dropped.",
                           parsed$truncated_id))
        } else NULL

        prune_note <- if (length(pruned$pruned_ids) > 0) {
          tags$div(class = "status-info", tags$i(class = "fa fa-info-circle"),
                   sprintf(" Auto-removed %d empty/disconnected entit(y/ies): %s",
                           length(pruned$pruned_ids), paste(pruned$pruned_ids, collapse = ", ")))
        } else NULL

        if (!validation$valid) {
          output$status <- renderUI({
            tagList(truncation_note, prune_note,
                    tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                             " The generated graph still has structural problems and was NOT uploaded:",
                             tags$ul(lapply(validation$issues, tags$li))))
          })
          showNotification("Graph validation failed - see details above.", type = "error", duration = 10)
          return()
        }

        graph_id <- generate_new_graph_id(parsed$topic)

        entity_rows <- data.frame(
          change_type = "create", row_kind = "entity",
          category = parsed$category, domain = parsed$domain, topic = parsed$topic,
          graph_id = graph_id, graph_title = parsed$graph_title,
          entity_id = parsed$entities$entity_id, entity_label = parsed$entities$entity_label,
          entity_type = parsed$entities$entity_type, entity_description = parsed$entities$entity_description,
          relationship_id = "", source_entity_id = "", predicate = "", target_entity_id = "",
          relationship_description = "", sort_order = parsed$entities$sort_order,
          stringsAsFactors = FALSE
        )

        relationship_rows <- data.frame(
          change_type = "create", row_kind = "relationship",
          category = parsed$category, domain = parsed$domain, topic = parsed$topic,
          graph_id = graph_id, graph_title = parsed$graph_title,
          entity_id = "", entity_label = "", entity_type = "", entity_description = "",
          relationship_id = parsed$relationships$relationship_id,
          source_entity_id = parsed$relationships$source_entity_id,
          predicate = parsed$relationships$predicate,
          target_entity_id = parsed$relationships$target_entity_id,
          relationship_description = parsed$relationships$relationship_description,
          sort_order = parsed$relationships$sort_order,
          stringsAsFactors = FALSE
        )

        upload_df <- rbind(entity_rows, relationship_rows)

        rows_uploaded <- api_manager$bq_insert(upload_df, source = "claude")
        api_manager$trigger_state_update()

        output$status <- renderUI({
          tagList(truncation_note, prune_note,
                  tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                           sprintf(" Uploaded %d entit(y/ies) and %d relationship(s) as a new graph (graph_id: %s). Check the Visualize tabs to view it.",
                                   nrow(parsed$entities), nrow(parsed$relationships), graph_id)),
                  if (length(validation$warnings) > 0) {
                    tags$div(class = "status-warning", tags$i(class = "fa fa-exclamation-triangle"),
                             " Non-blocking warnings (uploaded anyway):",
                             tags$ul(lapply(validation$warnings, tags$li)))
                  } else NULL)
        })

        showNotification(sprintf("✓ Uploaded %d entities, %d relationships!",
                                 nrow(parsed$entities), nrow(parsed$relationships)), type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$download <- downloadHandler(
      filename = function() {
        title_part <- if (nchar(trimws(input$graph_title)) > 0) input$graph_title else "knowledge_graph"
        paste0(gsub("[^A-Za-z0-9]+", "_", title_part), "_", format(Sys.Date(), "%Y%m%d"), ".txt")
      },
      content = function(file) { writeLines(input$generated_text_edit %||% "", file) }
    )

    output$status <- renderUI({ tags$div() })
    output$preview_html <- renderUI({ tags$div(class = "status-info", "Generate a knowledge graph above to see a preview here.") })

    session$onSessionEnded(function() {})
  })
}

render_kg_preview <- function(kg_text, max_relationships_per_entity = NULL) {
  parsed <- tryCatch(parse_kg_creation_text(kg_text), error = function(e) NULL)

  if (is.null(parsed) || nrow(parsed$entities) == 0) {
    return(tags$div(class = "status-warning", "Could not parse a preview - check the raw text format."))
  }

  pruned <- prune_empty_disconnected_entities(parsed$entities, parsed$relationships)
  parsed$entities <- pruned$entities

  validation <- validate_kg_structure(parsed$entities, parsed$relationships,
                                      max_relationships_per_entity = max_relationships_per_entity)
  outline_text <- serialize_graph_for_prompt(parsed$entities, parsed$relationships, max_words_per_item = 20)

  type_counts <- table(parsed$entities$entity_type)
  type_summary <- paste(sprintf("%s: %d", names(type_counts), as.integer(type_counts)), collapse = " | ")

  tagList(
    if (!is.null(parsed$truncated_id)) {
      tags$div(class = "status-warning", tags$i(class = "fa fa-cut"),
               sprintf(" Response appears TRUNCATED - block %s was incomplete and was dropped.", parsed$truncated_id))
    } else NULL,
    tags$p(class = "flex-table-note",
           sprintf("Parsed %d entit(y/ies) [%s], %d relationship(s)%s. Category: %s | Domain: %s | Topic: %s",
                   nrow(parsed$entities), type_summary, nrow(parsed$relationships),
                   if (length(pruned$pruned_ids) > 0) sprintf(" (%d auto-removed: %s)", length(pruned$pruned_ids),
                                                              paste(pruned$pruned_ids, collapse = ", ")) else "",
                   parsed$category, parsed$domain, parsed$topic)),
    if (!validation$valid) {
      tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
               " Structural issues detected (upload will be BLOCKED until fixed): ",
               tags$ul(lapply(validation$issues, tags$li)))
    } else {
      tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " Graph structure looks valid.")
    },
    if (length(validation$warnings) > 0) {
      tags$div(class = "status-warning", tags$i(class = "fa fa-exclamation-triangle"),
               " Non-blocking warnings: ", tags$ul(lapply(validation$warnings, tags$li)))
    } else NULL,
    tags$div(class = "viz-card",
             tags$pre(style = "white-space: pre-wrap; font-family: 'Courier New', monospace; font-size: 0.85em;",
                      outline_text)),
    tags$script(HTML("if (typeof MathJax !== 'undefined') { MathJax.Hub.Queue(['Typeset', MathJax.Hub]); }"))
  )
}
