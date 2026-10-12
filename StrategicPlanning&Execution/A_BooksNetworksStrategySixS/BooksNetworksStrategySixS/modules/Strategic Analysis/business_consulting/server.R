# modules/Strategic Analysis/business_consulting/server.R

business_consulting_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    loaded_strategy_data <- reactiveVal(NULL)   # full component rows of the loaded Strategy diagram
    loaded_sixsigma_data <- reactiveVal(NULL)   # full component rows of the loaded Six Sigma tool
    generated_case_df <- reactiveVal(NULL)      # parsed preview of the generated case

    # ============================================================
    # Box 1: Strategy Diagram cascade (Category -> Domain -> Topic ->
    # Diagram), prefixed sd_* to coexist with Box 2's independent ss_*
    # cascade and Box 3's category_topic_dropdown_ui() in the same page -
    # each of this module's three selectors needs its own distinct input
    # ids, since Shiny inputs must be unique within one module namespace.
    # Uses observe() (not observeEvent) at every level, the same fix
    # applied to every other cascade in this app: it depends on the
    # taxonomy directly, not just on the parent dropdown's value
    # changing, so a fresh upload is never silently hidden. This is a
    # simpler variant of diagram_visualizations' own cascade - no
    # auto-jump-to-newest here, since this is a supporting input
    # selector, not the primary diagram-browsing experience.
    # ============================================================
    sd_taxonomy <- reactive({
      api_manager$state_trigger_diagram()
      if (!api_manager$bq_authenticated) return(api_manager$empty_diagram_taxonomy())
      tryCatch(api_manager$bq_get_diagram_taxonomy(), error = function(e) api_manager$empty_diagram_taxonomy())
    })

    observe({
      tax <- sd_taxonomy()
      categories <- sort(unique(tax$category[nchar(trimws(tax$category)) > 0]))
      if (length(categories) == 0) { updateSelectInput(session, "sd_category", choices = c("(none yet)" = "")); return() }
      cur <- isolate(input$sd_category)
      sel <- if (!is.null(cur) && cur %in% categories) cur else categories[1]
      updateSelectInput(session, "sd_category", choices = setNames(categories, categories), selected = sel)
    })

    observe({
      tax <- sd_taxonomy(); cat_val <- input$sd_category
      if (is.null(cat_val) || cat_val == "") { updateSelectInput(session, "sd_domain", choices = c("(select category)" = "")); return() }
      domains <- sort(unique(tax$domain[tax$category == cat_val & nchar(trimws(tax$domain)) > 0]))
      if (length(domains) == 0) { updateSelectInput(session, "sd_domain", choices = c("(none found)" = "")); return() }
      cur <- isolate(input$sd_domain)
      sel <- if (!is.null(cur) && cur %in% domains) cur else domains[1]
      updateSelectInput(session, "sd_domain", choices = setNames(domains, domains), selected = sel)
    })

    observe({
      tax <- sd_taxonomy(); cat_val <- input$sd_category; dom_val <- input$sd_domain
      if (is.null(cat_val) || is.null(dom_val) || cat_val == "" || dom_val == "") {
        updateSelectInput(session, "sd_topic", choices = c("(select domain)" = "")); return()
      }
      topics <- sort(unique(tax$topic[tax$category == cat_val & tax$domain == dom_val & nchar(trimws(tax$topic)) > 0]))
      if (length(topics) == 0) { updateSelectInput(session, "sd_topic", choices = c("(none found)" = "")); return() }
      cur <- isolate(input$sd_topic)
      sel <- if (!is.null(cur) && cur %in% topics) cur else topics[1]
      updateSelectInput(session, "sd_topic", choices = setNames(topics, topics), selected = sel)
    })

    observe({
      tax <- sd_taxonomy(); cat_val <- input$sd_category; dom_val <- input$sd_domain; top_val <- input$sd_topic
      if (is.null(cat_val) || is.null(dom_val) || is.null(top_val) || cat_val == "" || dom_val == "" || top_val == "") {
        updateSelectInput(session, "sd_diagram_id", choices = c("(select topic)" = "")); return()
      }
      diagrams <- tax[tax$category == cat_val & tax$domain == dom_val & tax$topic == top_val, , drop = FALSE]
      if (nrow(diagrams) == 0) { updateSelectInput(session, "sd_diagram_id", choices = c("(none found)" = "")); return() }
      labels <- sprintf("%s - %s", diagrams$diagram_name, diagrams$title)
      cur <- isolate(input$sd_diagram_id)
      choices <- setNames(diagrams$diagram_id, labels)
      sel <- if (!is.null(cur) && cur %in% diagrams$diagram_id) cur else diagrams$diagram_id[1]
      updateSelectInput(session, "sd_diagram_id", choices = choices, selected = sel)
    })

    observeEvent(input$sd_load, {
      if (is.null(input$sd_diagram_id) || input$sd_diagram_id == "") {
        showNotification("Select a Strategy Diagram first.", type = "warning"); return()
      }
      tryCatch({
        components <- api_manager$bq_get_diagram_components(input$sd_diagram_id)
        if (nrow(components) == 0) {
          loaded_strategy_data(NULL)
          output$sd_status <- renderUI({ tags$div(class = "status-warning", "No rows found for this diagram.") })
          output$sd_output <- renderUI({ tags$div() })
          return()
        }
        loaded_strategy_data(components)
        output$sd_output <- renderUI({ render_diagram(components, components$diagram_type[1]) })
        output$sd_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Loaded '%s' (%d rows)", components$title[1], nrow(components)))
        })
        cat(sprintf("🖇️  [Business Consulting][DEBUG] Loaded Strategy Diagram: %s (%d rows)\n", input$sd_diagram_id, nrow(components)))
      }, error = function(e) {
        output$sd_status <- renderUI({ tags$div(class = "status-error", "Error: ", e$message) })
      })
    })

    # ============================================================
    # Box 2: Six Sigma Tool cascade (ss_* prefix), identical pattern
    # ============================================================
    ss_taxonomy <- reactive({
      api_manager$state_trigger_sixsigma()
      if (!api_manager$bq_authenticated) return(api_manager$empty_sixsigma_taxonomy())
      tryCatch(api_manager$bq_get_sixsigma_taxonomy(), error = function(e) api_manager$empty_sixsigma_taxonomy())
    })

    observe({
      tax <- ss_taxonomy()
      categories <- sort(unique(tax$category[nchar(trimws(tax$category)) > 0]))
      if (length(categories) == 0) { updateSelectInput(session, "ss_category", choices = c("(none yet)" = "")); return() }
      cur <- isolate(input$ss_category)
      sel <- if (!is.null(cur) && cur %in% categories) cur else categories[1]
      updateSelectInput(session, "ss_category", choices = setNames(categories, categories), selected = sel)
    })

    observe({
      tax <- ss_taxonomy(); cat_val <- input$ss_category
      if (is.null(cat_val) || cat_val == "") { updateSelectInput(session, "ss_domain", choices = c("(select category)" = "")); return() }
      domains <- sort(unique(tax$domain[tax$category == cat_val & nchar(trimws(tax$domain)) > 0]))
      if (length(domains) == 0) { updateSelectInput(session, "ss_domain", choices = c("(none found)" = "")); return() }
      cur <- isolate(input$ss_domain)
      sel <- if (!is.null(cur) && cur %in% domains) cur else domains[1]
      updateSelectInput(session, "ss_domain", choices = setNames(domains, domains), selected = sel)
    })

    observe({
      tax <- ss_taxonomy(); cat_val <- input$ss_category; dom_val <- input$ss_domain
      if (is.null(cat_val) || is.null(dom_val) || cat_val == "" || dom_val == "") {
        updateSelectInput(session, "ss_topic", choices = c("(select domain)" = "")); return()
      }
      topics <- sort(unique(tax$topic[tax$category == cat_val & tax$domain == dom_val & nchar(trimws(tax$topic)) > 0]))
      if (length(topics) == 0) { updateSelectInput(session, "ss_topic", choices = c("(none found)" = "")); return() }
      cur <- isolate(input$ss_topic)
      sel <- if (!is.null(cur) && cur %in% topics) cur else topics[1]
      updateSelectInput(session, "ss_topic", choices = setNames(topics, topics), selected = sel)
    })

    observe({
      tax <- ss_taxonomy(); cat_val <- input$ss_category; dom_val <- input$ss_domain; top_val <- input$ss_topic
      if (is.null(cat_val) || is.null(dom_val) || is.null(top_val) || cat_val == "" || dom_val == "" || top_val == "") {
        updateSelectInput(session, "ss_diagram_id", choices = c("(select topic)" = "")); return()
      }
      diagrams <- tax[tax$category == cat_val & tax$domain == dom_val & tax$topic == top_val, , drop = FALSE]
      if (nrow(diagrams) == 0) { updateSelectInput(session, "ss_diagram_id", choices = c("(none found)" = "")); return() }
      labels <- sprintf("%s - %s", diagrams$diagram_name, diagrams$title)
      cur <- isolate(input$ss_diagram_id)
      choices <- setNames(diagrams$diagram_id, labels)
      sel <- if (!is.null(cur) && cur %in% diagrams$diagram_id) cur else diagrams$diagram_id[1]
      updateSelectInput(session, "ss_diagram_id", choices = choices, selected = sel)
    })

    observeEvent(input$ss_load, {
      if (is.null(input$ss_diagram_id) || input$ss_diagram_id == "") {
        showNotification("Select a Six Sigma Tool first.", type = "warning"); return()
      }
      tryCatch({
        components <- api_manager$bq_get_sixsigma_components(input$ss_diagram_id)
        if (nrow(components) == 0) {
          loaded_sixsigma_data(NULL)
          output$ss_status <- renderUI({ tags$div(class = "status-warning", "No rows found for this diagram.") })
          output$ss_output <- renderUI({ tags$div() })
          return()
        }
        loaded_sixsigma_data(components)
        output$ss_output <- renderUI({ render_sixsigma(components, components$diagram_type[1]) })
        output$ss_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Loaded '%s' (%d rows)", components$title[1], nrow(components)))
        })
        cat(sprintf("🖇️  [Business Consulting][DEBUG] Loaded Six Sigma Tool: %s (%d rows)\n", input$ss_diagram_id, nrow(components)))
      }, error = function(e) {
        output$ss_status <- renderUI({ tags$div(class = "status-error", "Error: ", e$message) })
      })
    })

    # ============================================================
    # Box 3: Build the case
    # ============================================================
    cat_topic_react <- setup_category_topic_cascade(input, output, session, api_manager)

    output$inputs_summary <- renderUI({
      sd <- loaded_strategy_data(); ss <- loaded_sixsigma_data()
      sd_txt <- if (is.null(sd)) "not loaded" else sprintf("\u2713 %s", sd$title[1])
      ss_txt <- if (is.null(ss)) "not loaded" else sprintf("\u2713 %s", ss$title[1])
      HTML(sprintf("Strategy Diagram: %s &nbsp;|&nbsp; Six Sigma Tool: %s", sd_txt, ss_txt))
    })

    # Dummy button, deliberately not implemented yet - reserved for
    # pulling supporting content from another BigQuery table in future.
    observeEvent(input$load_from_db, {
      showNotification("Load Additional Info from DB is not implemented yet - reserved for a future update.", type = "message", duration = 6)
    })

    run_parse_preview <- function(text, quiet = FALSE) {
      if (trimws(text) == "") { generated_case_df(NULL); output$preview_table <- DT::renderDataTable({}); return(invisible(NULL)) }
      tryCatch({
        df <- parse_table_text(text)
        generated_case_df(df)
        output$preview_table <- DT::renderDataTable({
          DT::datatable(df, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
        })
        if (!quiet) {
          output$generate_status <- renderUI({
            tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " Parsed successfully.")
          })
        }
      }, error = function(e) {
        generated_case_df(NULL)
        output$preview_table <- DT::renderDataTable({})
        output$generate_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Parse issue: ", e$message)
        })
      })
    }

    observeEvent(input$generate, {
      if (!api_manager$claude_authenticated) {
        showNotification("Please configure and save Editing Tool API credentials first!", type = "error", duration = 10); return()
      }
      cdt <- cat_topic_react()
      if (nchar(cdt$category) == 0) { showNotification("Please select or enter a Category!", type = "error"); return() }
      if (nchar(cdt$topic) == 0) { showNotification("Please select or enter a Topic!", type = "error"); return() }
      if (nchar(trimws(input$table_title %||% "")) == 0) { showNotification("Please give the case a title!", type = "error"); return() }
      if (nchar(trimws(input$row_dimension_label %||% "")) == 0 || nchar(trimws(input$column_dimension_label %||% "")) == 0) {
        showNotification("Please specify what the rows and columns represent!", type = "error"); return()
      }
      has_context <- nchar(trimws(input$user_context %||% "")) > 0
      has_sd <- !is.null(loaded_strategy_data())
      has_ss <- !is.null(loaded_sixsigma_data())
      if (!has_context && !has_sd && !has_ss) {
        showNotification("Provide at least one input: a loaded Strategy Diagram, a loaded Six Sigma Tool, or written context.", type = "error", duration = 8)
        return()
      }

      shinyjs::show("loading_spinner")
      updateTextAreaInput(session, "case_text_edit", value = "")
      output$action_buttons <- renderUI({ tags$div() })
      output$generate_status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Building the case...")
      })

      sd_summary <- summarize_diagram_for_consulting(loaded_strategy_data())
      ss_summary <- summarize_sixsigma_for_consulting(loaded_sixsigma_data())
      request_description <- build_consulting_request_description(sd_summary, ss_summary, trimws(input$user_context %||% ""))

      prompt <- generate_table_prompt(
        category = cdt$category, topic = cdt$topic, table_title = input$table_title,
        row_dimension_label = input$row_dimension_label, column_dimension_label = input$column_dimension_label,
        request_description = request_description, include_latex = FALSE,
        words_per_cell = input$words_per_cell, expected_rows = input$expected_rows, expected_columns = input$expected_columns
      )
      max_tok <- estimate_max_tokens(input$expected_rows, input$expected_columns, input$words_per_cell, include_latex = FALSE)

      cat("========================================================\n")
      cat("🧠 [Business Consulting][DEBUG] Requesting business consulting case from the Editing Tool\n")
      cat(sprintf("    category/topic       : %s / %s\n", cdt$category, cdt$topic))
      cat(sprintf("    table_title          : %s\n", input$table_title))
      cat(sprintf("    has_strategy_diagram : %s%s\n", has_sd, if (has_sd) paste0(" (", loaded_strategy_data()$title[1], ")") else ""))
      cat(sprintf("    has_sixsigma_tool    : %s%s\n", has_ss, if (has_ss) paste0(" (", loaded_sixsigma_data()$title[1], ")") else ""))
      cat(sprintf("    has_user_context     : %s\n", has_context))
      cat(sprintf("    prompt_length        : %d characters | max_tokens: %d\n", nchar(prompt), max_tok))
      cat("========================================================\n")

      tryCatch({
        t0 <- Sys.time()
        response_text <- api_manager$call_claude(prompt = prompt, max_tokens = max_tok)
        elapsed <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)
        was_truncated <- identical(attr(response_text, "claude_stop_reason"), "max_tokens")

        cat(sprintf("🧠 [Business Consulting][DEBUG] Case generated in %ss (%d chars, truncated=%s)\n", elapsed, nchar(response_text), was_truncated))

        updateTextAreaInput(session, "case_text_edit", value = response_text)
        shinyjs::hide("loading_spinner")
        run_parse_preview(response_text, quiet = TRUE)

        output$action_buttons <- renderUI({
          fluidRow(
            column(4, actionButton(session$ns("copy_to_flex_bulk"), "Send to Flex Table Bulk Import", icon = icon("arrow-right"),
                                   class = "btn-success btn-lg", style = "width: 100%;")),
            column(4, downloadButton(session$ns("download"), "Download Text", class = "btn-warning", style = "width: 100%;")),
            column(4, actionButton(session$ns("reparse"), "Re-Parse Preview", icon = icon("sync"), style = "width: 100%;"))
          )
        })

        truncation_note <- if (was_truncated) tagList(tags$br(), tags$span(style = "color: #f39c12;", "⚠️ Response truncated - reduce Expected Rows/Columns or Max Words per Cell and try again")) else NULL
        output$generate_status <- renderUI({
          tags$div(class = if (was_truncated) "status-warning" else "status-success",
                   tags$i(class = if (was_truncated) "fa fa-exclamation-triangle" else "fa fa-check-circle"),
                   " ✓ Business consulting case generated!", truncation_note)
        })
        showNotification("✓ Case generated!", type = "message")

      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        cat(sprintf("❌ [Business Consulting][DEBUG] Generation failed: %s\n", e$message))
        output$generate_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Generation Failed: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 15)
      })
    })

    observeEvent(input$reparse, { run_parse_preview(input$case_text_edit) })

    observeEvent(input$copy_to_flex_bulk, {
      current_text <- input$case_text_edit
      if (nchar(trimws(current_text %||% "")) == 0) { showNotification("Nothing to send - generate a case first.", type = "warning"); return() }
      api_manager$set_pending_bulk_text_flex(current_text)
      updateTabItems(session$rootScope(), "sidebar_menu", selected = "bulk_import")
      showNotification("✓ Case sent to Flex Table's Bulk Import tab!", type = "message")
    })

    output$download <- downloadHandler(
      filename = function() paste0("business_consulting_case_", format(Sys.Date(), "%Y%m%d"), ".txt"),
      content = function(file) writeLines(input$case_text_edit %||% "", file)
    )

    output$sd_status <- renderUI({ tags$div() })
    output$sd_output <- renderUI({ tags$div() })
    output$ss_status <- renderUI({ tags$div() })
    output$ss_output <- renderUI({ tags$div() })
    output$generate_status <- renderUI({ tags$div() })
    output$action_buttons <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({})
    session$onSessionEnded(function() {})
  })
}
