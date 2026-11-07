# modules/generate_table/server.R

generate_table_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    table_data <- reactiveVal("")
    cat_topic <- setup_category_topic_cascade(input, output, session, api_manager)

    # Auto-fill dimension labels & title when an EXISTING topic is picked,
    # so the row/column axis meaning stays consistent for that topic.
    observeEvent(input$topic_select, {
      if (identical(input$topic_select, TOPIC_ADD_NEW_VALUE) || !api_manager$bq_authenticated) return()

      tryCatch({
        tax <- api_manager$bq_get_taxonomy()
        match_row <- tax[tax$category == input$category_select & tax$topic == input$topic_select, ]
        if (nrow(match_row) > 0) {
          updateTextInput(session, "table_title", value = match_row$table_title[1])
          updateTextInput(session, "row_dimension_label", value = match_row$row_dimension_label[1])
          updateTextInput(session, "column_dimension_label", value = match_row$column_dimension_label[1])
        }
      }, error = function(e) {})
    }, ignoreInit = TRUE)

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

      ct <- cat_topic()
      if (nchar(ct$category) == 0 || nchar(ct$topic) == 0) {
        showNotification("Please select or enter both Category and Topic!", type = "error")
        return()
      }

      if (nchar(trimws(input$row_dimension_label)) == 0 || nchar(trimws(input$column_dimension_label)) == 0) {
        showNotification("Please describe what the ROWS and COLUMNS represent!", type = "error")
        return()
      }

      if (nchar(trimws(input$request_description)) == 0) {
        showNotification("Please describe what you want compared!", type = "error")
        return()
      }

      table_title <- if (nchar(trimws(input$table_title)) > 0) trimws(input$table_title) else ct$topic

      include_latex <- identical(input$include_latex, "yes")
      words_per_cell <- input$words_per_cell %||% 40
      expected_rows <- input$expected_rows %||% 5
      expected_columns <- input$expected_columns %||% 5

      dynamic_max_tokens <- estimate_max_tokens(
        expected_rows = expected_rows,
        expected_columns = expected_columns,
        words_per_cell = words_per_cell,
        include_latex = include_latex
      )

      shinyjs::show("loading_spinner")
      output$generated_table_text <- renderText({ "" })

      progress_msg <- reactiveVal("Initializing...")
      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " ", progress_msg())
      })

      prompt <- tryCatch({
        generate_table_prompt(
          category = ct$category,
          topic = ct$topic,
          table_title = table_title,
          row_dimension_label = trimws(input$row_dimension_label),
          column_dimension_label = trimws(input$column_dimension_label),
          request_description = trimws(input$request_description),
          include_latex = include_latex,
          words_per_cell = words_per_cell,
          expected_rows = expected_rows,
          expected_columns = expected_columns
        )
      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Failed to build prompt: ", e$message)
        })
        NULL
      })

      if (is.null(prompt)) return()

      tryCatch({
        progress_msg("Building prompt...")
        Sys.sleep(0.2)
        progress_msg("Connecting to Claude API...")
        Sys.sleep(0.2)
        progress_msg(sprintf("Sending request (budgeted ~%d tokens for ~%d rows x %d columns, %d words/cell)...",
                             dynamic_max_tokens, expected_rows, expected_columns, words_per_cell))

        table_text <- api_manager$call_claude(
          prompt = prompt,
          max_tokens = dynamic_max_tokens,
          progress_callback = function(msg) progress_msg(msg)
        )

        table_data(table_text)
        output$generated_table_text <- renderText({ table_text })

        # Live preview
        output$preview_html <- renderUI({
          render_table_preview(table_text)
        })

        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " ✓ Table generated successfully!",
                   tags$br(),
                   tags$small(sprintf("Generated %d characters", nchar(table_text))))
        })

        shinyjs::hide("loading_spinner")
        showNotification("✓ Table generated successfully!", type = "message")

      }, error = function(e) {
        shinyjs::hide("loading_spinner")

        error_message <- e$message
        suggestion <- ""
        if (grepl("timeout", error_message, ignore.case = TRUE)) {
          suggestion <- "💡 Try: Increase timeout in Claude API Config (recommended: 300-600 seconds)"
        } else if (grepl("network|peer|connection", error_message, ignore.case = TRUE)) {
          suggestion <- "💡 Try: Check internet connection, firewall settings, or try again in a moment"
        } else if (grepl("401|authentication", error_message, ignore.case = TRUE)) {
          suggestion <- "💡 Try: Re-enter your API key in Claude API Config"
        } else if (grepl("429|rate limit", error_message, ignore.case = TRUE)) {
          suggestion <- "💡 Try: Wait a few moments and try again"
        }

        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Generation Failed",
                   tags$br(),
                   tags$strong("Error: "), tags$small(error_message),
                   if (nchar(suggestion) > 0) {
                     tagList(tags$br(), tags$br(), tags$span(style = "color: #f39c12;", suggestion))
                   } else NULL)
        })

        showNotification(paste("Error:", error_message), type = "error", duration = 15)
      })
    })

    # Copy to bulk import
    observeEvent(input$copy_to_bulk, {
      if (nchar(table_data()) > 0) {
        api_manager$set_pending_bulk_text(table_data())
        updateTabItems(session$rootScope(), "sidebar_menu", selected = "bulk_import")
        showNotification("✓ Table copied to Bulk Import tab!", type = "message")
      } else {
        showNotification("No table to copy. Generate first.", type = "warning")
      }
    })

    # Parse and upload direct
    observeEvent(input$parse_and_upload, {

      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }

      if (nchar(table_data()) == 0) {
        showNotification("No table to upload. Generate first.", type = "warning")
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Parsing and uploading...")
      })

      tryCatch({
        parsed_df <- parse_table_text(table_data())
        rows_uploaded <- api_manager$bq_insert(parsed_df, source = "claude")

        api_manager$trigger_state_update()

        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully uploaded %d rows! Table Viewer updated.", rows_uploaded))
        })

        showNotification(sprintf("✓ Uploaded %d rows!", rows_uploaded), type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$download <- downloadHandler(
      filename = function() {
        title_part <- if (nchar(trimws(input$table_title)) > 0) input$table_title else "comparison_table"
        paste0(gsub("[^A-Za-z0-9]+", "_", title_part), "_", format(Sys.Date(), "%Y%m%d"), ".txt")
      },
      content = function(file) {
        writeLines(table_data(), file)
      }
    )

    output$generated_table_text <- renderText({ "" })
    output$status <- renderUI({ tags$div() })
    output$preview_html <- renderUI({ tags$div(class = "status-info", "Generate a table above to see a live preview here.") })

    session$onSessionEnded(function() {})
  })
}

# Small standalone preview renderer shared by the generate/bulk_import
# modules - shows just the first couple of rows so the user can sanity
# check the delimiter parsing worked before uploading.
render_table_preview <- function(table_text, max_rows = 3) {
  parsed <- tryCatch(parse_table_text(table_text), error = function(e) NULL)

  if (is.null(parsed) || nrow(parsed) == 0) {
    return(tags$div(class = "status-warning", "Could not parse a preview - check the raw text format."))
  }

  n_preview <- min(max_rows, nrow(parsed))
  cards <- lapply(seq_len(n_preview), function(i) {
    row <- parsed[i, ]
    cols <- parse_columns_data(row$columns_data)

    tags$div(class = "viz-card",
      tags$div(class = "chapter-title", tags$i(class = "fa fa-table"), " ", row$row_index),
      if (nrow(cols) > 0) {
        tagList(lapply(seq_len(nrow(cols)), function(j) {
          tags$div(style = "margin-bottom: 8px;",
                   tags$strong(cols$header[j], ": "),
                   tags$span(cols$value[j]))
        }))
      } else {
        tags$em("No columns_data parsed for this row.")
      }
    )
  })

  tagList(
    tags$p(class = "flex-table-note",
           sprintf("Parsed %d row(s), %d shown. Category: %s | Topic: %s | Rows = %s | Columns = %s",
                   nrow(parsed), n_preview, parsed$category[1], parsed$topic[1],
                   parsed$row_dimension_label[1], parsed$column_dimension_label[1])),
    do.call(tagList, cards),
    tags$script(HTML("if (typeof MathJax !== 'undefined') { MathJax.Hub.Queue(['Typeset', MathJax.Hub]); }"))
  )
}
