# modules/Six Sigma Analysis/sixsigma_add_single/server.R

sixsigma_add_single_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    cat_dom_topic_react <- setup_category_domain_topic_cascade(
      input, output, session, api_manager,
      taxonomy_method = "bq_get_sixsigma_taxonomy",
      empty_taxonomy_method = "empty_sixsigma_taxonomy",
      state_trigger_field = "state_trigger_sixsigma"
    )
    setup_sixsigma_group_type_cascade(input, output, session)

    observeEvent(input$add_component, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      if (nchar(trimws(input$label_text %||% "")) == 0) { showNotification("Label Text is required!", type = "error"); return() }
      if (nchar(trimws(input$title %||% "")) == 0) { showNotification("Diagram Title is required!", type = "error"); return() }
      if (is.null(input$diagram_type_select) || nchar(input$diagram_type_select) == 0) {
        showNotification("Please select a Diagram Type!", type = "error"); return()
      }

      cdt <- cat_dom_topic_react()
      if (nchar(cdt$topic) == 0) { showNotification("Please select or enter a Topic!", type = "error"); return() }

      diag_id <- if (nchar(trimws(input$diagram_id_existing %||% "")) > 0) {
        trimws(input$diagram_id_existing)
      } else {
        generate_new_sixsigma_id(cdt$topic)
      }

      items_lines <- strsplit(input$items_raw %||% "", "\n")[[1]]
      items_lines <- trimws(items_lines[nchar(trimws(items_lines)) > 0])
      items_packed <- if (length(items_lines) > 0) paste(items_lines, collapse = SS_ITEM_SEP) else "N/A"

      num_or_na <- function(x) if (is.null(x) || is.na(x) || nchar(trimws(as.character(x))) == 0) NA_real_ else suppressWarnings(as.numeric(x))
      int_or_na <- function(x) if (is.null(x) || is.na(x)) NA_integer_ else suppressWarnings(as.integer(x))
      txt_or_na <- function(x) if (nchar(trimws(x %||% "")) > 0) trimws(x) else NA_character_

      row_df <- data.frame(
        diagram_id = diag_id, diagram_name = SIXSIGMA_TYPE_LABELS[[input$diagram_type_select]],
        diagram_type = input$diagram_type_select, diagram_group = input$diagram_group_select,
        category = cdt$category, domain = cdt$domain, topic = cdt$topic,
        title = input$title, is_template = FALSE, source_diagram_id = NA_character_,
        component_type = input$component_type, layout_role = input$layout_role,
        grid_row = as.integer(input$grid_row), grid_col = as.integer(input$grid_col),
        quadrant_position = if (input$quadrant_position == "N/A") NA_character_ else input$quadrant_position,
        sequence_order = as.integer(input$sequence_order), z_index = NA_integer_,
        pos_x = NA_real_, pos_y = NA_real_, width = NA_real_, height = NA_real_,
        label_text = input$label_text, sub_text = input$sub_text %||% "", items_packed = items_packed,
        value_numeric = num_or_na(input$value_numeric), value_axis = NA_character_,
        series_name = NA_character_, unit_label = NA_character_,
        axis_type = NA_character_, axis_min = NA_real_, axis_max = NA_real_, metric_name = NA_character_,
        severity = int_or_na(input$severity), occurrence = int_or_na(input$occurrence), detection = int_or_na(input$detection),
        component_ref = txt_or_na(input$component_ref), parent_ref = txt_or_na(input$parent_ref),
        color_hint = txt_or_na(input$color_hint), icon_name = txt_or_na(input$icon_name),
        created_by = "manual_add_single",
        stringsAsFactors = FALSE
      )

      tryCatch({
        rows_uploaded <- api_manager$bq_insert_sixsigma(row_df)
        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Component added to diagram_id %s", diag_id))
        })
        updateTextInput(session, "diagram_id_existing", value = diag_id)
        showNotification("✓ Component added!", type = "message")
      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$status <- renderUI({ tags$div() })
  })
}
