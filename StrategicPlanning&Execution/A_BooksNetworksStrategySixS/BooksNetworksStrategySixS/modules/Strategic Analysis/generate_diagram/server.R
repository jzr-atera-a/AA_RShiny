# modules/Strategic Analysis/generate_diagram/server.R

generate_diagram_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed_preview <- reactiveVal(NULL)
    current_diagram_id <- reactiveVal(NULL)

    # Shared 3-level Category -> Domain -> Topic cascade (same helper Mind
    # Map/Knowledge Graph's Generate tabs use), backed by this suite's own
    # taxonomy/state trigger.
    cat_dom_topic_react <- setup_category_domain_topic_cascade(
      input, output, session, api_manager,
      taxonomy_method = "bq_get_diagram_taxonomy",
      empty_taxonomy_method = "empty_diagram_taxonomy",
      state_trigger_field = "state_trigger_diagram"
    )

    # Independent Diagram Group -> Framework cascade (which strategic lens,
    # then which of the ~29 specific named frameworks within it).
    setup_diagram_group_type_cascade(input, output, session)

    # Tool Recommender -> Generate Diagram handoff: when a recommended
    # framework's name is clicked on the Tool Recommender tab, its
    # diagram_type id is stored on api_manager and the user is switched
    # to this tab. This observer picks that up and auto-selects both the
    # Group and Framework dropdowns to match. Both dropdowns are set
    # explicitly here (not left to setup_diagram_group_type_cascade's own
    # group-change observer to fill in the Framework choices) because
    # that observer's re-fire happens on a LATER reactive flush, after
    # the browser round-trips the Group change back - setting Framework's
    # choices AND selection directly here, in the same pass as Group,
    # avoids relying on timing between the two. (It's still safe for that
    # other observer to also fire afterward: it never passes `selected=`,
    # so per Shiny's update*Input semantics it preserves whatever is
    # already selected - the value this observer set - rather than
    # clearing it.)
    observeEvent(api_manager$pending_diagram_selection(), {
      dtype <- api_manager$pending_diagram_selection()
      if (is.null(dtype) || !dtype %in% DIAGRAM_TYPES) return()

      grp <- names(which(sapply(DIAGRAM_TYPES_BY_GROUP, function(x) dtype %in% x)))[1]
      if (is.null(grp) || is.na(grp)) return()

      cat(sprintf("🎯 [Strategic Analysis][DEBUG] Auto-selecting recommended framework: %s (group: %s)\n", dtype, grp))

      updateSelectInput(session, "diagram_group_select",
                        choices = setNames(DIAGRAM_GROUPS, DIAGRAM_GROUP_LABELS[DIAGRAM_GROUPS]), selected = grp)
      types <- DIAGRAM_TYPES_BY_GROUP[[grp]]
      updateSelectInput(session, "diagram_type_select",
                        choices = setNames(types, DIAGRAM_TYPE_LABELS[types]), selected = dtype)

      # Consume it so revisiting this tab later (without a fresh click)
      # doesn't keep re-forcing the same selection over the user's own
      # subsequent manual changes.
      api_manager$set_pending_diagram_selection(NULL)
    }, ignoreNULL = TRUE, ignoreInit = TRUE)

    run_parse_preview <- function(text, quiet = FALSE) {
      if (trimws(text) == "") {
        parsed_preview(NULL)
        output$preview_table <- DT::renderDataTable({})
        return(invisible(NULL))
      }
      cdt <- cat_dom_topic_react()
      tryCatch({
        diag_id <- current_diagram_id() %||% generate_new_diagram_id(cdt$topic)
        current_diagram_id(diag_id)

        # diagram_type/diagram_group/category/domain/topic/title now come
        # FROM the text itself (the metadata block Claude was instructed
        # to write) - only diagram_id is supplied by the app, same
        # convention as every other suite's Generate tab.
        df <- parse_diagram_text(text, diagram_id = diag_id, is_template = FALSE, created_by = "claude_agent")
        parsed_preview(df)
        output$preview_table <- DT::renderDataTable({
          DT::datatable(df[, c("component_type", "layout_role", "grid_row", "grid_col",
                                "sequence_order", "label_text", "sub_text", "items_packed")],
                       options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
        })
        if (!quiet) {
          output$status <- renderUI({
            tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                     sprintf(" Parsed %d component row(s) (%s [%s] / %s / %s / %s)",
                             nrow(df), df$diagram_type[1], df$diagram_group[1], df$category[1], df$domain[1], df$topic[1]))
          })
        }
      }, error = function(e) {
        parsed_preview(NULL)
        output$preview_table <- DT::renderDataTable({})
        if (!quiet) {
          output$status <- renderUI({
            tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Parse issue (blocking): ", e$message)
          })
        }
      })
    }

    observeEvent(input$generate, {

      if (!api_manager$claude_authenticated) {
        showNotification("Please configure and save Claude API credentials first!", type = "error", duration = 10)
        return()
      }
      cdt <- cat_dom_topic_react()
      if (nchar(cdt$category) == 0) { showNotification("Please select or enter a Category!", type = "error"); return() }
      if (nchar(cdt$domain) == 0) { showNotification("Please select or enter a Domain!", type = "error"); return() }
      if (nchar(cdt$topic) == 0) { showNotification("Please select or enter a Topic!", type = "error"); return() }
      if (is.null(input$diagram_type_select) || nchar(input$diagram_type_select) == 0) {
        showNotification("Please select a Framework!", type = "error"); return()
      }
      if (nchar(trimws(input$user_request %||% "")) == 0) { showNotification("Please describe what the diagram should cover!", type = "error"); return() }

      # New diagram_id for every fresh generation
      new_diag_id <- generate_new_diagram_id(cdt$topic)
      current_diagram_id(new_diag_id)

      shinyjs::show("loading_spinner")
      updateTextAreaInput(session, "diagram_text_edit", value = "")

      progress_msg <- reactiveVal("Initializing...")
      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " ", progress_msg())
      })

      title_hint <- trimws(input$title_hint %||% "")
      diagram_type <- input$diagram_type_select
      diagram_group <- input$diagram_group_select

      prompt <- generate_diagram_prompt(
        diagram_type = diagram_type,
        diagram_group = diagram_group,
        category = cdt$category,
        domain = cdt$domain,
        topic = cdt$topic,
        title_hint = title_hint,
        user_request = input$user_request
      )

      # ---- DEBUG: everything about this generation request, printed to
      #     the console every time a new diagram is generated via Claude. --
      cat("========================================================\n")
      cat("🧠 [Strategic Analysis][DEBUG] Requesting diagram generation from Claude\n")
      cat(sprintf("    diagram_id      : %s\n", new_diag_id))
      cat(sprintf("    diagram_type    : %s (group: %s)\n", diagram_type, diagram_group))
      cat(sprintf("    category        : %s\n", cdt$category))
      cat(sprintf("    domain          : %s\n", cdt$domain))
      cat(sprintf("    topic           : %s\n", cdt$topic))
      cat(sprintf("    title_hint      : %s\n", ifelse(nchar(title_hint) > 0, title_hint, "(none - Claude will choose)")))
      cat(sprintf("    user_request    : %s\n", input$user_request))
      cat(sprintf("    prompt_length   : %d characters\n", nchar(prompt)))
      cat(sprintf("    claude_model    : %s\n", api_manager$claude_model))
      cat("========================================================\n")

      tryCatch({
        progress_msg("Generating (this may take 20-60 seconds)...")

        t0 <- Sys.time()
        response_text <- api_manager$call_claude(
          prompt = prompt,
          progress_callback = function(msg) { progress_msg(msg) }
        )
        elapsed <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)
        was_truncated <- identical(attr(response_text, "claude_stop_reason"), "max_tokens")

        # Force diagram_type/diagram_group/category/domain/topic back to
        # the authoritative dropdown values regardless of what Claude
        # echoed; only force the title if the user explicitly gave one,
        # otherwise keep Claude's own invented title.
        diagram_text <- overwrite_diagram_header(
          response_text, diagram_type, diagram_group, cdt$category, cdt$domain, cdt$topic,
          title_override = if (nchar(title_hint) > 0) title_hint else NULL
        )

        # ---- DEBUG: what came back, before any parsing happens ----------
        cat("--------------------------------------------------------\n")
        cat("🧠 [Strategic Analysis][DEBUG] Claude generation complete\n")
        cat(sprintf("    elapsed_seconds : %s\n", elapsed))
        cat(sprintf("    response_chars  : %d\n", nchar(response_text)))
        cat(sprintf("    truncated       : %s\n", was_truncated))
        cat(sprintf("    delimiter_check : contains '%s'? %s\n",
                    DIAG_ITEM_SEP, grepl(DIAG_ITEM_SEP, diagram_text, fixed = TRUE)))
        cat("--------------------------------------------------------\n")

        updateTextAreaInput(session, "diagram_text_edit", value = diagram_text)
        shinyjs::hide("loading_spinner")

        run_parse_preview(diagram_text, quiet = TRUE)

        truncation_note <- if (was_truncated) {
          tagList(tags$br(), tags$span(style = "color: #f39c12;",
                                        "⚠️ Response truncated - increase Max Tokens and try again"))
        } else NULL

        output$status <- renderUI({
          tags$div(class = if (was_truncated) "status-warning" else "status-success",
                   tags$i(class = if (was_truncated) "fa fa-exclamation-triangle" else "fa fa-check-circle"),
                   " ✓ Diagram generated!", truncation_note)
        })
        showNotification("✓ Diagram generated!", type = "message")

      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        error_message <- e$message
        cat(sprintf("❌ [Strategic Analysis][DEBUG] Generation failed: %s\n", error_message))
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Generation Failed",
                   tags$br(), tags$strong("Error: "), tags$small(error_message))
        })
        showNotification(paste("Error:", error_message), type = "error", duration = 15)
      })
    })

    observeEvent(input$reparse, {
      run_parse_preview(input$diagram_text_edit)
    })

    observeEvent(input$copy_to_bulk, {
      current_text <- input$diagram_text_edit
      if (nchar(trimws(current_text %||% "")) > 0) {
        api_manager$set_pending_bulk_text_diagram(current_text)
        updateTabItems(session$rootScope(), "sidebar_menu", selected = "diagram_bulk_import")
        showNotification("✓ Diagram copied to Bulk Import tab!", type = "message")
      } else {
        showNotification("No diagram to copy. Generate one first.", type = "warning")
      }
    })

    observeEvent(input$parse_and_upload, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      current_text <- input$diagram_text_edit
      if (nchar(trimws(current_text %||% "")) == 0) { showNotification("No diagram to upload. Generate one first.", type = "warning"); return() }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing and uploading...")
      })

      cdt <- cat_dom_topic_react()
      tryCatch({
        diag_id <- current_diagram_id() %||% generate_new_diagram_id(cdt$topic)
        parsed_df <- parse_diagram_text(current_text, diagram_id = diag_id, is_template = FALSE, created_by = "claude_agent")
        rows_uploaded <- api_manager$bq_insert_diagram(parsed_df)

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully uploaded %d component row(s)! Diagram ID: %s", rows_uploaded, diag_id))
        })
        showNotification(sprintf("✓ Uploaded %d component row(s)!", rows_uploaded), type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$download <- downloadHandler(
      filename = function() paste0("diagram_", format(Sys.Date(), "%Y%m%d"), ".txt"),
      content = function(file) writeLines(input$diagram_text_edit %||% "", file)
    )

    output$status <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({})

    session$onSessionEnded(function() {})
  })
}
