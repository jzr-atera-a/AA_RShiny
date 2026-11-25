# modules/Flex Table/add_entry.R
# ---- module --------------------------------------------------------------------------------------
# id:           add_entry
# name:         Add Single Entry
# icon:         plus-circle
# description:  Manually add one row (with any number of custom columns) to a table
# packages:     shiny, shinydashboard
# api_required: bigquery
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

add_entry_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Add a Single Row Manually",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        p("Use this to add or correct one row by hand. You can enter as many columns as you like - ",
          "one per line, in the form ", tags$code("Column Header: Value"), ". ",
          "Values may include LaTeX (", tags$code("$...$"), " or ", tags$code("$$...$$"), ")."),

        category_topic_dropdown_ui(ns),

        fluidRow(
          column(6, textInput(ns("table_title"), "Table Title:", placeholder = "e.g., ML Models for Forecasting Asset Class Prices")),
          column(3, textInput(ns("row_dimension_label"), "Row Dimension Label:", placeholder = "e.g., Financial Asset Class")),
          column(3, textInput(ns("column_dimension_label"), "Column Dimension Label:", placeholder = "e.g., Machine Learning Model"))
        ),

        textInput(ns("row_index"), "Row Label (row_index): *", placeholder = "e.g., Equities"),

        textAreaInput(ns("columns_text"), "Columns (one 'Header: Value' per line): *", rows = 8, width = "100%",
                      placeholder = "Random Forest: Handles nonlinearity well; needs regular retraining as regime shifts.\nLSTM: Captures long-range dependencies; data-hungry and slow to train.\nARIMA: Simple, interpretable baseline; struggles with structural breaks."),

        textInput(ns("notes"), "Notes (optional):", placeholder = "One-sentence note about this row as a whole"),

        br(),
        actionButton(ns("submit"), "Submit Entry", class = "btn-success btn-lg",
                    icon = icon("save"), style = "width: 100%;"),
        br(), br(),
        htmlOutput(ns("status"))
      )
    )
  )
}

# ==== Server =======================================================================================

add_entry_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    cat_topic <- setup_category_topic_cascade(input, output, session, api_manager)

    # Auto-fill dimension labels when an existing topic is chosen
    observeEvent(input$topic_select, {
      if (identical(input$topic_select, TOPIC_ADD_NEW_VALUE) || !api_manager$bq_authenticated) return()

      tryCatch({
        tax <- api_manager$bq_get_flex_taxonomy()
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

        api_manager$bq_insert_flex(df, source = "manual")
        api_manager$trigger_state_update_flex()

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
                   " Error: ", app_err_text(e))
        })
        showNotification(paste("Error:", app_err_text(e)), type = "error")
      })
    })

    output$status <- renderUI({ tags$div() })
  })
}
