# modules/table_viewer/server.R

table_viewer_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    wide_data <- reactiveVal(NULL)  # data.frame used for CSV download

    # Column width slider: applies INSTANTLY via a CSS custom property,
    # no need to re-query BigQuery or re-render the table HTML.
    observeEvent(input$column_width_chars, {
      shinyjs::runjs(sprintf(
        "document.documentElement.style.setProperty('--flex-col-width', '%dch');",
        input$column_width_chars
      ))
    })

    # ------------------------------------------------------------
    # Level 1: Category -> Level 2: Topic
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
    # Level 3: Rows Label (row_dimension_label), populated once
    # Category + Topic are set. A single Category+Topic can contain
    # several distinct subtables (e.g. "Arms Top 3" vs "Legs Top 7"),
    # each with its own row_dimension_label / column_dimension_label
    # pairing, so this is a real filter, not a display-only field.
    # ------------------------------------------------------------
    observeEvent(input$viz_topic, {
      if (!api_manager$bq_authenticated || is.null(input$viz_category) || is.null(input$viz_topic) ||
          input$viz_category == "" || input$viz_topic == "") {
        updateSelectInput(session, "row_label_select", choices = c("(select a topic first)" = ""))
        return()
      }

      tryCatch({
        safe_category <- gsub("'", "''", input$viz_category)
        safe_topic <- gsub("'", "''", input$viz_topic)
        query <- sprintf(
          "SELECT DISTINCT row_dimension_label FROM `%s` WHERE category = '%s' AND topic = '%s' ORDER BY row_dimension_label",
          api_manager$bq_full_table_id, safe_category, safe_topic
        )
        rows <- api_manager$bq_query(query)

        if (nrow(rows) > 0) {
          updateSelectInput(session, "row_label_select",
                            choices = setNames(rows$row_dimension_label, rows$row_dimension_label))
        } else {
          updateSelectInput(session, "row_label_select", choices = c("(none found)" = ""))
        }
      }, error = function(e) {
        updateSelectInput(session, "row_label_select", choices = c("(error loading)" = ""))
      })
    }, ignoreInit = TRUE)

    # ------------------------------------------------------------
    # Level 4: Columns Label (column_dimension_label), populated once
    # Category + Topic + Rows Label are set.
    # ------------------------------------------------------------
    observeEvent(input$row_label_select, {
      if (!api_manager$bq_authenticated || is.null(input$viz_category) || is.null(input$viz_topic) ||
          is.null(input$row_label_select) || input$viz_category == "" || input$viz_topic == "" ||
          input$row_label_select == "") {
        updateSelectInput(session, "column_label_select", choices = c("(select a rows label first)" = ""))
        return()
      }

      tryCatch({
        safe_category <- gsub("'", "''", input$viz_category)
        safe_topic <- gsub("'", "''", input$viz_topic)
        safe_row_label <- gsub("'", "''", input$row_label_select)

        query <- sprintf(
          "SELECT DISTINCT column_dimension_label FROM `%s` WHERE category = '%s' AND topic = '%s' AND row_dimension_label = '%s' ORDER BY column_dimension_label",
          api_manager$bq_full_table_id, safe_category, safe_topic, safe_row_label
        )
        cols <- api_manager$bq_query(query)

        if (nrow(cols) > 0) {
          updateSelectInput(session, "column_label_select",
                            choices = setNames(cols$column_dimension_label, cols$column_dimension_label))
        } else {
          updateSelectInput(session, "column_label_select", choices = c("(none found)" = ""))
        }
      }, error = function(e) {
        updateSelectInput(session, "column_label_select", choices = c("(error loading)" = ""))
      })
    }, ignoreInit = TRUE)

    # ------------------------------------------------------------
    # Load and render the FULL comparison grid for this exact
    # Category + Topic + Rows Label + Columns Label combination
    # ------------------------------------------------------------
    observeEvent(input$load_table, {

      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }

      missing <- c()
      if (is.null(input$viz_category) || input$viz_category == "") missing <- c(missing, "Category")
      if (is.null(input$viz_topic) || input$viz_topic == "") missing <- c(missing, "Topic")
      if (is.null(input$row_label_select) || input$row_label_select == "") missing <- c(missing, "Rows Label")
      if (is.null(input$column_label_select) || input$column_label_select == "") missing <- c(missing, "Columns Label")

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
                 " Loading table data...")
      })

      tryCatch({
        safe_category <- gsub("'", "''", input$viz_category)
        safe_topic <- gsub("'", "''", input$viz_topic)
        safe_row_label <- gsub("'", "''", input$row_label_select)
        safe_col_label <- gsub("'", "''", input$column_label_select)

        query <- sprintf(
          "SELECT * FROM `%s` WHERE category = '%s' AND topic = '%s' AND row_dimension_label = '%s' AND column_dimension_label = '%s' ORDER BY id",
          api_manager$bq_full_table_id, safe_category, safe_topic, safe_row_label, safe_col_label
        )

        data <- api_manager$bq_query(query)

        if (nrow(data) == 0) {
          output$status <- renderUI({
            tags$div(class = "status-warning",
                     tags$i(class = "fa fa-exclamation-triangle"),
                     " No data found for this combination")
          })
          return()
        }

        # ------------------------------------------------------------
        # Reassemble the flexible column set: union of column headers
        # across ALL rows, preserving first-seen order.
        # ------------------------------------------------------------
        per_row_cols <- lapply(seq_len(nrow(data)), function(i) parse_columns_data(data$columns_data[i]))

        all_headers <- character(0)
        for (cols in per_row_cols) {
          new_headers <- setdiff(cols$header, all_headers)
          all_headers <- c(all_headers, new_headers)
        }

        has_notes <- any(!is.na(data$notes) & trimws(as.character(data$notes)) != "")

        # Build a wide data.frame for CSV export
        wide_df <- data.frame(Row = data$row_index, stringsAsFactors = FALSE)
        for (h in all_headers) {
          wide_df[[h]] <- vapply(per_row_cols, function(cols) {
            match_idx <- which(cols$header == h)
            if (length(match_idx) > 0) cols$value[match_idx[1]] else ""
          }, character(1))
        }
        if (has_notes) wide_df[["Notes"]] <- as.character(data$notes)
        wide_data(wide_df)

        # Table header - uses row_dimension_label / column_dimension_label
        # as the human-readable axis meanings, exactly as stored.
        output$table_header <- renderUI({
          tags$div(class = "book-header",
                   tags$h2(data$table_title[1]),
                   tags$div(class = "author",
                            tags$i(class = "fa fa-tag"), " ", data$category[1], " › ", data$topic[1]))
        })

        output$total_rows <- renderValueBox({
          valueBox(nrow(data), data$row_dimension_label[1], icon = icon("list-ol"), color = "aqua")
        })
        output$total_columns <- renderValueBox({
          valueBox(length(all_headers), data$column_dimension_label[1], icon = icon("columns"), color = "blue")
        })
        output$row_dim <- renderValueBox({
          valueBox(data$row_dimension_label[1], "Rows Represent", icon = icon("bars"), color = "green")
        })
        output$col_dim <- renderValueBox({
          valueBox(data$column_dimension_label[1], "Columns Represent", icon = icon("border-all"), color = "yellow")
        })

        # ------------------------------------------------------------
        # Build the scrollable HTML comparison table
        # ------------------------------------------------------------
        output$comparison_table_html <- renderUI({

          html <- c()
          html <- c(html, sprintf(
            '<div class="flex-table-outer"><p>%s columns detected <span class="flex-column-count-badge">%d columns</span></p><div class="flex-table-scroll"><table class="flex-comparison-table"><thead><tr>',
            htmltools::htmlEscape(data$column_dimension_label[1]), length(all_headers)
          ))

          html <- c(html, sprintf('<th>%s</th>', htmltools::htmlEscape(data$row_dimension_label[1])))
          for (h in all_headers) {
            html <- c(html, sprintf('<th>%s</th>', h))
          }
          if (has_notes) html <- c(html, '<th>Notes</th>')
          html <- c(html, '</tr></thead><tbody>')

          for (i in seq_len(nrow(data))) {
            cols <- per_row_cols[[i]]
            html <- c(html, '<tr>')
            html <- c(html, sprintf('<th class="row-index-cell">%s</th>', data$row_index[i]))

            for (h in all_headers) {
              match_idx <- which(cols$header == h)
              val <- if (length(match_idx) > 0) cols$value[match_idx[1]] else ""
              # NOT html-escaped on purpose: values may legitimately contain
              # $...$ / $$...$$ LaTeX which MathJax needs to see as literal
              # text in the DOM. Content comes from our own Claude prompt /
              # manual entry form, not arbitrary third-party HTML.
              html <- c(html, sprintf('<td>%s</td>', val))
            }
            if (has_notes) {
              html <- c(html, sprintf('<td>%s</td>', as.character(data$notes[i])))
            }
            html <- c(html, '</tr>')
          }

          html <- c(html, '</tbody></table></div></div>')
          html <- c(html, '<script>if (typeof MathJax !== "undefined") { MathJax.Hub.Queue(["Typeset", MathJax.Hub]); }</script>')

          HTML(paste(html, collapse = ""))
        })

        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Loaded '%s' (%d rows x %d columns)", data$table_title[1], nrow(data), length(all_headers)))
        })

        showNotification("✓ Table loaded!", type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$download_wide_csv <- downloadHandler(
      filename = function() {
        paste0("comparison_table_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        if (!is.null(wide_data())) {
          write.csv(wide_data(), file, row.names = FALSE)
        } else {
          write.csv(data.frame(Message = "No table loaded yet"), file, row.names = FALSE)
        }
      }
    )

    # Default outputs
    output$status <- renderUI({ tags$div() })
    output$table_header <- renderUI({ tags$div() })
    output$comparison_table_html <- renderUI({
      tags$div(class = "status-info", "Select Category, Topic, Rows Label, and Columns Label above, then click 'Load Table'.")
    })
    output$total_rows <- renderValueBox({ valueBox(0, "Rows", icon = icon("list-ol"), color = "aqua") })
    output$total_columns <- renderValueBox({ valueBox(0, "Columns", icon = icon("columns"), color = "blue") })
    output$row_dim <- renderValueBox({ valueBox("-", "Rows Represent", icon = icon("bars"), color = "green") })
    output$col_dim <- renderValueBox({ valueBox("-", "Columns Represent", icon = icon("border-all"), color = "yellow") })

    session$onSessionEnded(function() {})
  })
}
