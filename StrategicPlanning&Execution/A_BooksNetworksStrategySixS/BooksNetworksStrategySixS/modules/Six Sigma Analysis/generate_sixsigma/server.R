# modules/Six Sigma Analysis/generate_sixsigma/server.R

generate_sixsigma_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed_preview <- reactiveVal(NULL)
    current_diagram_id <- reactiveVal(NULL)

    cat_dom_topic_react <- setup_category_domain_topic_cascade(
      input, output, session, api_manager,
      taxonomy_method = "bq_get_sixsigma_taxonomy",
      empty_taxonomy_method = "empty_sixsigma_taxonomy",
      state_trigger_field = "state_trigger_sixsigma"
    )
    setup_sixsigma_group_type_cascade(input, output, session)

    # Tool Recommender -> Generate Six Sigma Diagram handoff: when a
    # recommended tool's name is clicked on the Tool Recommender tab, its
    # diagram_type id is stored on api_manager and the user is switched
    # to this tab. This observer picks that up and auto-selects both the
    # Group and Type dropdowns to match, setting both explicitly in one
    # pass rather than relying on setup_sixsigma_group_type_cascade's own
    # group-change observer to fill in Type's choices on a later reactive
    # flush (that observer never passes `selected=`, so it's still safe
    # for it to also fire afterward - it preserves whatever this observer
    # already selected rather than clearing it).
    observeEvent(api_manager$pending_sixsigma_selection(), {
      dtype <- api_manager$pending_sixsigma_selection()
      if (is.null(dtype) || !dtype %in% SIXSIGMA_ALL_TYPES) return()

      grp <- names(which(sapply(SIXSIGMA_TYPES_BY_GROUP, function(x) dtype %in% x)))[1]
      if (is.null(grp) || is.na(grp)) return()

      cat(sprintf("🎯 [Six Sigma Analysis][DEBUG] Auto-selecting recommended tool: %s (group: %s)\n", dtype, grp))

      updateSelectInput(session, "diagram_group_select",
                        choices = setNames(SIXSIGMA_GROUPS, SIXSIGMA_GROUP_LABELS[SIXSIGMA_GROUPS]), selected = grp)
      types <- SIXSIGMA_TYPES_BY_GROUP[[grp]]
      updateSelectInput(session, "diagram_type_select",
                        choices = setNames(types, SIXSIGMA_TYPE_LABELS[types]), selected = dtype)

      # Consume it so revisiting this tab later doesn't keep re-forcing
      # the same selection over the user's own subsequent manual changes.
      api_manager$set_pending_sixsigma_selection(NULL)
    }, ignoreNULL = TRUE, ignoreInit = TRUE)

    run_parse_preview <- function(text, quiet = FALSE) {
      if (trimws(text) == "") {
        parsed_preview(NULL)
        output$preview_table <- DT::renderDataTable({})
        return(invisible(NULL))
      }
      cdt <- cat_dom_topic_react()
      tryCatch({
        diag_id <- current_diagram_id() %||% generate_new_sixsigma_id(cdt$topic)
        current_diagram_id(diag_id)

        df <- parse_sixsigma_text(text, diagram_id = diag_id, is_template = FALSE, created_by = "claude_agent")
        parsed_preview(df)
        output$preview_table <- DT::renderDataTable({
          DT::datatable(df[, c("component_type", "layout_role", "grid_row", "grid_col",
                                "sequence_order", "label_text", "sub_text", "items_packed")],
                       options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
        })
        if (!quiet) {
          output$status <- renderUI({
            tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                     sprintf(" Parsed %d component row(s) (%s / %s / %s / %s / %s)",
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
        showNotification("Please select a Diagram Type!", type = "error"); return()
      }
      if (nchar(trimws(input$user_request %||% "")) == 0) { showNotification("Please describe the process/problem!", type = "error"); return() }

      new_diag_id <- generate_new_sixsigma_id(cdt$topic)
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

      prompt <- generate_sixsigma_prompt(
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
      cat("🧠 [Six Sigma Analysis][DEBUG] Requesting diagram generation from Claude\n")
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

        diagram_text <- overwrite_sixsigma_header(
          response_text, diagram_type, diagram_group, cdt$category, cdt$domain, cdt$topic,
          title_override = if (nchar(title_hint) > 0) title_hint else NULL
        )

        # ---- DEBUG: what came back, before any parsing happens ----------
        cat("--------------------------------------------------------\n")
        cat("🧠 [Six Sigma Analysis][DEBUG] Claude generation complete\n")
        cat(sprintf("    elapsed_seconds : %s\n", elapsed))
        cat(sprintf("    response_chars  : %d\n", nchar(response_text)))
        cat(sprintf("    truncated       : %s\n", was_truncated))
        cat(sprintf("    delimiter_check : contains '%s'? %s\n",
                    SS_ITEM_SEP, grepl(SS_ITEM_SEP, diagram_text, fixed = TRUE)))
        cat(sprintf("    arithmetic_check: response contains a literal pct sign (possible cumulative-pct leakage)? %s\n",
                    grepl("%", response_text, fixed = TRUE)))
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
        cat(sprintf("❌ [Six Sigma Analysis][DEBUG] Generation failed: %s\n", error_message))
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
        api_manager$set_pending_bulk_text_sixsigma(current_text)
        updateTabItems(session$rootScope(), "sidebar_menu", selected = "sixsigma_bulk_import")
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
        diag_id <- current_diagram_id() %||% generate_new_sixsigma_id(cdt$topic)
        parsed_df <- parse_sixsigma_text(current_text, diagram_id = diag_id, is_template = FALSE, created_by = "claude_agent")
        rows_uploaded <- api_manager$bq_insert_sixsigma(parsed_df)

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
      filename = function() paste0("sixsigma_", format(Sys.Date(), "%Y%m%d"), ".txt"),
      content = function(file) writeLines(input$diagram_text_edit %||% "", file)
    )

    output$status <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({})

    session$onSessionEnded(function() {})
  })
}
