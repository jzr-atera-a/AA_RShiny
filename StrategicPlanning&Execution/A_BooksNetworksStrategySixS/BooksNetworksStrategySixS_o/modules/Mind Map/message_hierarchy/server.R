# modules/message_hierarchy/server.R

message_hierarchy_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    # Category is locked to the reserved MessageHierarchy value.
    cat_dom_topic <- setup_category_domain_topic_cascade(
      input, output, session, api_manager,
      "bq_get_mindmap_taxonomy_messages", "empty_mindmap_taxonomy", "state_trigger_mindmap",
      fixed_category = MESSAGE_HIERARCHY_CATEGORY
    )
    observe({ shinyjs::disable("category_select") })

    # Viewer (shared with the regular Mind Map viewer) - messages only
    mindmap_viewer_logic(input, output, session, api_manager, "bq_get_mindmap_taxonomy_messages")

    observeEvent(input$generate, {

      if (!api_manager$claude_authenticated) {
        showNotification("Please configure and save Editing Tool API credentials first!", type = "error", duration = 10)
        return()
      }
      cdt <- cat_dom_topic()
      if (nchar(cdt$domain) == 0 || nchar(cdt$topic) == 0) {
        showNotification("Please select or enter a Domain and Topic!", type = "error")
        return()
      }
      if (nchar(trimws(input$core_message)) == 0 || nchar(trimws(input$outcome)) == 0) {
        showNotification("Please enter the core message and the critical outcome!", type = "error")
        return()
      }

      n_points <- input$n_points %||% 3
      ev <- input$evidence_per_point %||% 2
      words_per_node <- input$words_per_node %||% 40
      total_nodes <- 1 + n_points + n_points * ev
      map_title <- if (nchar(trimws(input$map_title)) > 0) trimws(input$map_title) else cdt$topic

      request <- build_message_hierarchy_request(
        core_message = trimws(input$core_message), n_points = n_points,
        outcome = trimws(input$outcome), audience = input$audience %||% "",
        reference = input$reference %||% "", evidence_per_point = ev,
        extra = input$extra %||% ""
      )
      prompt <- generate_mindmap_prompt(
        category = MESSAGE_HIERARCHY_CATEGORY, domain = cdt$domain, topic = cdt$topic,
        map_title = map_title, request_description = request,
        include_latex = FALSE, words_per_node = words_per_node,
        max_nodes = total_nodes, max_depth = 2,
        max_root_children = n_points, max_children_per_node = max(ev, 1)
      )
      max_tokens <- estimate_mindmap_max_tokens(total_nodes, words_per_node, FALSE)

      shinyjs::show("loading_spinner")
      updateTextAreaInput(session, "generated_text_edit", value = "")
      progress_msg <- reactiveVal("Sending request...")
      output$gen_status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " ", progress_msg())
      })

      tryCatch({
        response_text <- api_manager$call_claude(
          prompt = prompt, max_tokens = max_tokens,
          progress_callback = function(msg) progress_msg(msg)
        )
        truncated <- identical(attr(response_text, "claude_stop_reason"), "max_tokens")
        updateTextAreaInput(session, "generated_text_edit", value = response_text)
        output$preview_html <- renderUI({
          render_mindmap_preview(response_text, max_root_children = n_points,
                                 max_children_per_node = max(ev, 1))
        })
        output$gen_status <- renderUI({
          if (truncated) {
            tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                     " Response was cut off by the token limit. Reduce the points/evidence or words per node and regenerate.")
          } else {
            tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                     sprintf(" Generated (%d characters). Review, then 'Parse & Upload Direct'.", nchar(response_text)))
          }
        })
        shinyjs::hide("loading_spinner")
      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        output$gen_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Generation failed: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 15)
      })
    })

    observeEvent(input$reparse_preview, {
      if (nchar(trimws(input$generated_text_edit)) == 0) {
        showNotification("Nothing to re-parse - the text box is empty.", type = "warning")
        return()
      }
      output$preview_html <- renderUI({
        render_mindmap_preview(input$generated_text_edit,
                               max_root_children = input$n_points %||% 3,
                               max_children_per_node = max(input$evidence_per_point %||% 2, 1))
      })
    })

    observeEvent(input$parse_and_upload, {
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      if (nchar(trimws(input$generated_text_edit)) == 0) {
        showNotification("Nothing to upload. Generate first.", type = "warning")
        return()
      }
      cdt <- cat_dom_topic()
      if (nchar(cdt$domain) == 0 || nchar(cdt$topic) == 0) {
        showNotification("Please select or enter a Domain and Topic!", type = "error")
        return()
      }

      tryCatch({
        parsed <- parse_mindmap_creation_text(input$generated_text_edit)
        pruned <- prune_empty_disconnected_nodes(parsed$nodes)
        parsed$nodes <- pruned$nodes

        validation <- validate_tree_structure(
          parsed$nodes,
          max_root_children = input$n_points %||% 3,
          max_children_per_node = max(input$evidence_per_point %||% 2, 1)
        )
        if (!validation$valid) {
          output$gen_status <- renderUI({
            tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                     " Structural problems - NOT uploaded:", tags$ul(lapply(validation$issues, tags$li)))
          })
          return()
        }

        title <- if (nchar(trimws(input$map_title)) > 0) trimws(input$map_title) else parsed$map_title
        map_id <- generate_new_map_id(title)

        upload_df <- parsed$nodes
        upload_df$change_type <- "create"
        # Category/domain/topic are enforced from the dropdowns, never trusted from Claude's echo.
        upload_df$category <- MESSAGE_HIERARCHY_CATEGORY
        upload_df$domain <- cdt$domain
        upload_df$topic <- cdt$topic
        upload_df$map_id <- map_id
        upload_df$map_title <- title

        n <- api_manager$bq_insert_mindmap(upload_df, source = "claude")
        api_manager$trigger_state_update_mindmap()

        output$gen_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Uploaded %d node(s) as '%s' (map_id: %s). Select it in 'View a Saved Message Hierarchy' below.",
                           n, title, map_id))
        })
        showNotification(sprintf("✓ Uploaded %d node(s)!", n), type = "message")
      }, error = function(e) {
        output$gen_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$download <- downloadHandler(
      filename = function() paste0("message_hierarchy_", format(Sys.Date(), "%Y%m%d"), ".txt"),
      content = function(file) writeLines(input$generated_text_edit %||% "", file)
    )

    session$onSessionEnded(function() {})
  })
}
