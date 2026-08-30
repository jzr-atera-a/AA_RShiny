# modules/table_viewer/server.R

table_viewer_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    # ------------------------------------------------------------
    # Level 1: Category -> Level 2: Topic
    # (same taxonomy cascade pattern used elsewhere in the app)
    # ------------------------------------------------------------
    viz_taxonomy <- reactive({
      api_manager$state_trigger()
      if (!api_manager$bq_authenticated) return(api_manager$empty_taxonomy())
      tryCatch(api_manager$bq_get_taxonomy(), error = function(e) api_manager$empty_taxonomy())
    })

    observeEvent(viz_taxonomy(), {
      tax <- viz_taxonomy()
      categories <- sort(unique(tax$category[nchar(trimws(tax$category)) > 0]))

      current <- isolate(input$viz_category)

      if (length(categories) == 0) {
        updateSelectInput(session, "viz_category", choices = c("(no categories yet)" = ""))
      } else {
        selected <- if (!is.null(current) && current %in% categories) current else categories[1]
        updateSelectInput(session, "viz_category", choices = setNames(categories, categories), selected = selected)
      }
    }, ignoreNULL = FALSE)

    observeEvent(input$viz_category, {
      tax <- viz_taxonomy()

      if (is.null(input$viz_category) || input$viz_category == "") {
        updateSelectInput(session, "viz_topic", choices = c("(select a category first)" = ""))
        return()
      }

      topics <- sort(unique(tax$topic[tax$category == input$viz_category & nchar(trimws(tax$topic)) > 0]))

      if (length(topics) == 0) {
        updateSelectInput(session, "viz_topic", choices = c("(no topics for this category)" = ""))
      } else {
        updateSelectInput(session, "viz_topic", choices = setNames(topics, topics))
      }
    }, ignoreInit = TRUE)

    # ------------------------------------------------------------
    # Level 3: Row (row_index), populated once Category + Topic are set
    # ------------------------------------------------------------
    observeEvent(input$viz_topic, {
      if (!api_manager$bq_authenticated || is.null(input$viz_category) || is.null(input$viz_topic) ||
          input$viz_category == "" || input$viz_topic == "") {
        updateSelectInput(session, "row_select", choices = c("(select a topic first)" = ""))
        return()
      }

      tryCatch({
        safe_category <- gsub("'", "''", input$viz_category)
        safe_topic <- gsub("'", "''", input$viz_topic)
        query <- sprintf("SELECT DISTINCT row_index FROM `%s` WHERE category = '%s' AND topic = '%s' ORDER BY row_index",
                         api_manager$bq_full_table_id, safe_category, safe_topic)
        rows <- api_manager$bq_query(query)

        if (nrow(rows) > 0) {
          updateSelectInput(session, "row_select", choices = setNames(rows$row_index, rows$row_index))
        } else {
          updateSelectInput(session, "row_select", choices = c("(no rows found)" = ""))
        }
      }, error = function(e) {
        updateSelectInput(session, "row_select", choices = c("(error loading rows)" = ""))
      })
    }, ignoreInit = TRUE)

    # ------------------------------------------------------------
    # Level 4: Columns Data (the column HEADER, e.g. one specific ML
    # Model), populated once Category + Topic + Row are set. Headers
    # are read back from the most recent stored row for that
    # combination (columns_data is delimited text, not a SQL column,
    # so this parse happens client-side after a single-row fetch).
    # ------------------------------------------------------------
    observeEvent(input$row_select, {
      if (!api_manager$bq_authenticated || is.null(input$viz_category) || is.null(input$viz_topic) ||
          is.null(input$row_select) || input$viz_category == "" || input$viz_topic == "" ||
          input$row_select == "") {
        updateSelectInput(session, "column_select", choices = c("(select a row first)" = ""))
        return()
      }

      tryCatch({
        safe_category <- gsub("'", "''", input$viz_category)
        safe_topic <- gsub("'", "''", input$viz_topic)
        safe_row <- gsub("'", "''", input$row_select)

        query <- sprintf(
          "SELECT columns_data FROM `%s` WHERE category = '%s' AND topic = '%s' AND row_index = '%s' ORDER BY id DESC LIMIT 1",
          api_manager$bq_full_table_id, safe_category, safe_topic, safe_row
        )
        result <- api_manager$bq_query(query)

        if (nrow(result) == 0) {
          updateSelectInput(session, "column_select", choices = c("(no columns found)" = ""))
          return()
        }

        cols <- parse_columns_data(result$columns_data[1])
        headers <- unique(cols$header[nchar(trimws(cols$header)) > 0])

        if (length(headers) == 0) {
          updateSelectInput(session, "column_select", choices = c("(no columns found)" = ""))
        } else {
          updateSelectInput(session, "column_select", choices = setNames(headers, headers))
        }
      }, error = function(e) {
        updateSelectInput(session, "column_select", choices = c("(error loading columns)" = ""))
      })
    }, ignoreInit = TRUE)

    # ------------------------------------------------------------
    # Render exactly ONE combination: Category + Topic + Row + Column
    # ------------------------------------------------------------
    observeEvent(input$view_value, {

      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }

      missing <- c()
      if (is.null(input$viz_category) || input$viz_category == "") missing <- c(missing, "Category")
      if (is.null(input$viz_topic) || input$viz_topic == "") missing <- c(missing, "Topic")
      if (is.null(input$row_select) || input$row_select == "") missing <- c(missing, "Row")
      if (is.null(input$column_select) || input$column_select == "") missing <- c(missing, "Columns Data")

      if (length(missing) > 0) {
        showNotification(paste("Please select:", paste(missing, collapse = ", ")), type = "warning")
        output$status <- renderUI({
          tags$div(class = "status-warning",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   sprintf(" All four filters are required. Missing: %s", paste(missing, collapse = ", ")))
        })
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Loading value...")
      })

      tryCatch({
        safe_category <- gsub("'", "''", input$viz_category)
        safe_topic <- gsub("'", "''", input$viz_topic)
        safe_row <- gsub("'", "''", input$row_select)

        query <- sprintf(
          "SELECT * FROM `%s` WHERE category = '%s' AND topic = '%s' AND row_index = '%s' ORDER BY id DESC LIMIT 1",
          api_manager$bq_full_table_id, safe_category, safe_topic, safe_row
        )
        data <- api_manager$bq_query(query)

        if (nrow(data) == 0) {
          output$status <- renderUI({
            tags$div(class = "status-warning",
                     tags$i(class = "fa fa-exclamation-triangle"),
                     " No data found for this combination")
          })
          output$value_display <- renderUI({
            tags$div(class = "status-info", "No data found for this combination.")
          })
          return()
        }

        cols <- parse_columns_data(data$columns_data[1])
        match_idx <- which(cols$header == input$column_select)
        value <- if (length(match_idx) > 0) cols$value[match_idx[1]] else NA

        has_notes <- !is.na(data$notes[1]) && trimws(as.character(data$notes[1])) != ""

        output$value_display <- renderUI({
          tagList(
            tags$div(class = "book-header",
                     tags$h2(data$table_title[1]),
                     tags$div(class = "author",
                              tags$i(class = "fa fa-tag"), " ", data$category[1], " › ", data$topic[1])),

            tags$div(class = "viz-card",
              tags$div(class = "chapter-title",
                       tags$i(class = "fa fa-bookmark"), " ",
                       data$row_dimension_label[1], ": ", data$row_index[1]),
              tags$div(class = "section-tag",
                       data$column_dimension_label[1], ": ", input$column_select),
              if (is.na(value)) {
                tags$div(class = "status-warning",
                         tags$i(class = "fa fa-exclamation-triangle"),
                         " This column was not found in the stored data for this row.")
              } else {
                tags$div(class = "details-text", value)
              },
              if (has_notes) {
                tags$div(style = "margin-top: 15px; padding: 10px; background: #f8f9fa; border-radius: 8px;",
                         tags$strong("Notes: "), as.character(data$notes[1]))
              } else NULL
            ),
            tags$script(HTML("if (typeof MathJax !== 'undefined') { MathJax.Hub.Queue(['Typeset', MathJax.Hub]); }"))
          )
        })

        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " Value loaded")
        })

        showNotification("✓ Value loaded!", type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    # Default outputs
    output$status <- renderUI({ tags$div() })
    output$value_display <- renderUI({
      tags$div(class = "status-info",
               "Select a Category, Topic, Row, and Columns Data entry above, then click 'View Value'.")
    })

    session$onSessionEnded(function() {})
  })
}
