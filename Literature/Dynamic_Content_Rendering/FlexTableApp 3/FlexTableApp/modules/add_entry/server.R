# modules/add_entry/server.R

add_entry_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    cat_topic <- setup_category_topic_cascade(input, output, session, api_manager)

    # Auto-fill dimension labels when an existing topic is chosen
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

    # Turn "Header: Value" lines into a header/value vector pair
    parse_columns_text <- function(text) {
      lines <- strsplit(text, "\n")[[1]]
      lines <- trimws(lines)
      lines <- lines[nchar(lines) > 0]

      headers <- character(0)
      values <- character(0)

      for (line in lines) {
        if (grepl(":", line, fixed = TRUE)) {
          parts <- strsplit(line, ":", fixed = TRUE)[[1]]
          headers <- c(headers, trimws(parts[1]))
          values <- c(values, trimws(paste(parts[-1], collapse = ":")))
        }
      }

      list(headers = headers, values = values)
    }

    observeEvent(input$submit, {

      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }

      ct <- cat_topic()
      if (nchar(ct$category) == 0 || nchar(ct$topic) == 0) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please select or enter both Category and Topic")
        })
        return()
      }

      if (trimws(input$row_index) == "" || trimws(input$columns_text) == "") {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please fill in the Row Label and at least one column")
        })
        return()
      }

      cols <- parse_columns_text(input$columns_text)
      if (length(cols$headers) == 0) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " No valid 'Header: Value' lines found")
        })
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Submitting...")
      })

      tryCatch({
        table_title <- if (nchar(trimws(input$table_title)) > 0) trimws(input$table_title) else ct$topic

        df <- data.frame(
          category = ct$category,
          topic = ct$topic,
          table_title = table_title,
          row_dimension_label = if (nchar(trimws(input$row_dimension_label)) > 0) trimws(input$row_dimension_label) else "Row",
          column_dimension_label = if (nchar(trimws(input$column_dimension_label)) > 0) trimws(input$column_dimension_label) else "Column",
          row_index = trimws(input$row_index),
          columns_data = build_columns_data(cols$headers, cols$values),
          notes = trimws(input$notes %||% ""),
          stringsAsFactors = FALSE
        )

        api_manager$bq_insert(df, source = "manual")
        api_manager$trigger_state_update()

        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Entry submitted with %d column(s)!", length(cols$headers)))
        })

        showNotification("✓ Entry submitted!", type = "message")

        updateTextInput(session, "row_index", value = "")
        updateTextAreaInput(session, "columns_text", value = "")
        updateTextInput(session, "notes", value = "")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$status <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
