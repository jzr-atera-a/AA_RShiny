# modules/Sankey Graph/generate_sankey/server.R

generate_sankey_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed_preview <- reactiveVal(NULL)
    current_sankey_id <- reactiveVal(NULL)

    cat_dom_topic_react <- setup_category_domain_topic_cascade(
      input, output, session, api_manager,
      taxonomy_method = "bq_get_sankey_taxonomy",
      empty_taxonomy_method = "empty_sankey_taxonomy",
      state_trigger_field = "state_trigger_sankey"
    )

    run_parse_preview <- function(text, quiet = FALSE) {
      if (trimws(text) == "") {
        parsed_preview(NULL)
        output$preview_table <- DT::renderDataTable({})
        return(invisible(NULL))
      }
      cdt <- cat_dom_topic_react()
      tryCatch({
        sky_id <- current_sankey_id() %||% generate_new_sankey_id(cdt$topic)
        current_sankey_id(sky_id)

        df <- parse_sankey_text(text, sankey_id = sky_id, is_template = FALSE, created_by = "claude_agent")
        parsed_preview(df)
        output$preview_table <- DT::renderDataTable({
          DT::datatable(df[, c("row_kind", "component_ref", "column_index", "sequence_order",
                                "label_text", "source_ref", "target_ref", "value_numeric", "unit_label")],
                       options = list(pageLength = 12, scrollX = TRUE), rownames = FALSE)
        })
        if (!quiet) {
          node_count <- sum(df$row_kind == "node")
          link_count <- sum(df$row_kind == "link")
          output$status <- renderUI({
            tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                     sprintf(" Parsed %d node(s) and %d link(s) across %d columns (%s / %s / %s)",
                             node_count, link_count, df$num_columns[1], df$category[1], df$domain[1], df$topic[1]))
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
      if (nchar(trimws(input$user_request %||% "")) == 0) { showNotification("Please describe the flow!", type = "error"); return() }

      new_sky_id <- generate_new_sankey_id(cdt$topic)
      current_sankey_id(new_sky_id)

      shinyjs::show("loading_spinner")
      updateTextAreaInput(session, "sankey_text_edit", value = "")

      progress_msg <- reactiveVal("Initializing...")
      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " ", progress_msg())
      })

      title_hint <- trimws(input$title_hint %||% "")
      num_columns <- input$num_columns
      num_initial_rows <- input$num_initial_rows

      prompt <- generate_sankey_prompt(
        category = cdt$category, domain = cdt$domain, topic = cdt$topic,
        title_hint = title_hint, num_columns = num_columns, num_initial_rows = num_initial_rows,
        user_request = input$user_request
      )

      # ---- DEBUG: everything about this generation request ----
      cat("========================================================\n")
      cat("🧠 [Sankey Graph][DEBUG] Requesting Sankey generation from Claude\n")
      cat(sprintf("    sankey_id       : %s\n", new_sky_id))
      cat(sprintf("    num_columns     : %d\n", num_columns))
      cat(sprintf("    num_initial_rows: %d\n", num_initial_rows))
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

        sankey_text <- overwrite_sankey_header(
          response_text, num_columns, num_initial_rows, cdt$category, cdt$domain, cdt$topic,
          title_override = if (nchar(title_hint) > 0) title_hint else NULL
        )

        # ---- DEBUG: what came back ----
        cat("--------------------------------------------------------\n")
        cat("🧠 [Sankey Graph][DEBUG] Claude generation complete\n")
        cat(sprintf("    elapsed_seconds : %s\n", elapsed))
        cat(sprintf("    response_chars  : %d\n", nchar(response_text)))
        cat(sprintf("    truncated       : %s\n", was_truncated))
        cat(sprintf("    delimiter_check : contains '%s'? %s\n",
                    SANKEY_ITEM_SEP, grepl(SANKEY_ITEM_SEP, sankey_text, fixed = TRUE)))
        cat("--------------------------------------------------------\n")

        updateTextAreaInput(session, "sankey_text_edit", value = sankey_text)
        shinyjs::hide("loading_spinner")

        run_parse_preview(sankey_text, quiet = TRUE)

        truncation_note <- if (was_truncated) {
          tagList(tags$br(), tags$span(style = "color: #f39c12;",
                                        "⚠️ Response truncated - increase Max Tokens and try again"))
        } else NULL

        output$status <- renderUI({
          tags$div(class = if (was_truncated) "status-warning" else "status-success",
                   tags$i(class = if (was_truncated) "fa fa-exclamation-triangle" else "fa fa-check-circle"),
                   " ✓ Sankey generated!", truncation_note)
        })
        showNotification("✓ Sankey generated!", type = "message")

      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        error_message <- e$message
        cat(sprintf("❌ [Sankey Graph][DEBUG] Generation failed: %s\n", error_message))
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Generation Failed",
                   tags$br(), tags$strong("Error: "), tags$small(error_message))
        })
        showNotification(paste("Error:", error_message), type = "error", duration = 15)
      })
    })

    observeEvent(input$reparse, {
      run_parse_preview(input$sankey_text_edit)
    })

    observeEvent(input$copy_to_bulk, {
      current_text <- input$sankey_text_edit
      if (nchar(trimws(current_text %||% "")) > 0) {
        api_manager$set_pending_bulk_text_sankey(current_text)
        updateTabItems(session$rootScope(), "sidebar_menu", selected = "sankey_bulk_import")
        showNotification("✓ Sankey copied to Bulk Import tab!", type = "message")
      } else {
        showNotification("No Sankey to copy. Generate one first.", type = "warning")
      }
    })

    observeEvent(input$parse_and_upload, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      current_text <- input$sankey_text_edit
      if (nchar(trimws(current_text %||% "")) == 0) { showNotification("No Sankey to upload. Generate one first.", type = "warning"); return() }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing and uploading...")
      })

      cdt <- cat_dom_topic_react()
      tryCatch({
        sky_id <- current_sankey_id() %||% generate_new_sankey_id(cdt$topic)
        parsed_df <- parse_sankey_text(current_text, sankey_id = sky_id, is_template = FALSE, created_by = "claude_agent")
        rows_uploaded <- api_manager$bq_insert_sankey(parsed_df)

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully uploaded %d row(s)! Sankey ID: %s", rows_uploaded, sky_id))
        })
        showNotification(sprintf("✓ Uploaded %d row(s)!", rows_uploaded), type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$download <- downloadHandler(
      filename = function() paste0("sankey_", format(Sys.Date(), "%Y%m%d"), ".txt"),
      content = function(file) writeLines(input$sankey_text_edit %||% "", file)
    )

    output$status <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({})

    session$onSessionEnded(function() {})
  })
}
