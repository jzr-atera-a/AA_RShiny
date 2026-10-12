# modules/Technical Designs/techdesign_library/server.R

techdesign_library_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    current_design <- reactiveVal(NULL)
    current_id <- reactiveVal(NULL)
    set_status <- function(cls, msg) output$status <- renderUI(tags$div(class = cls, msg))

    lib <- reactive({
      api_manager$state_trigger_techdesign()
      input$refresh
      if (!api_manager$bq_authenticated) return(data.frame())
      api_manager$bq_get_techdesign_list()
    })

    filtered <- reactive({
      df <- lib()
      if (nrow(df) == 0) return(df)
      if (nzchar(input$group %||% "")) df <- df[df$design_group == input$group, , drop = FALSE]
      q <- tolower(trimws(input$search %||% ""))
      if (nzchar(q) && nrow(df) > 0) {
        hay <- tolower(paste(df$title, df$tags, df$design_type, df$variant, df$summary))
        df <- df[grepl(q, hay, fixed = TRUE), , drop = FALSE]
      }
      df
    })

    output$list <- DT::renderDataTable({
      df <- filtered()
      if (nrow(df) == 0) return(DT::datatable(data.frame(Message = if (api_manager$bq_authenticated) "No saved designs match." else "Authenticate with BigQuery to see saved designs."),
                                              rownames = FALSE, options = list(dom = "t")))
      show <- data.frame(Title = df$title, Variant = df$variant, Group = unlist(TD_GROUP_LABELS[df$design_group]), Type = df$design_type,
                         Complexity = df$complexity_level, Tags = df$tags, Saved = format(df$created_at, "%Y-%m-%d %H:%M"), stringsAsFactors = FALSE)
      DT::datatable(show, rownames = FALSE, selection = "single", options = list(pageLength = 10, scrollX = TRUE))
    })

    selected_id <- function() {
      i <- input$list_rows_selected
      df <- filtered()
      if (is.null(i) || nrow(df) == 0) { showNotification("Select a design in the list first.", type = "warning"); return(NULL) }
      df$design_id[i]
    }

    draw <- function(d) {
      current_design(d)
      output$diagram <- renderUI(export_capture_wrapper(session$ns, render_techdesign(d), d$meta$title))
    }

    load_versions <- function(did) {
      output$versions <- DT::renderDataTable({
        v <- api_manager$bq_get_techdesign_versions(did)
        if (nrow(v) == 0) return(NULL)
        DT::datatable(data.frame(Row = v$id, Saved = format(v$created_at, "%Y-%m-%d %H:%M:%S"), Change = v$change_type, Title = v$title,
                                 Variant = v$variant, By = v$created_by, stringsAsFactors = FALSE),
                      rownames = FALSE, selection = "single", options = list(pageLength = 8, dom = "tp"))
      })
    }

    observeEvent(input$show, {
      did <- selected_id(); if (is.null(did)) return()
      row <- api_manager$bq_get_techdesign(did)
      if (nrow(row) == 0) { showNotification("Could not load that design.", type = "error"); return() }
      current_id(did); draw(techdesign_from_row(row)); load_versions(did)
      set_status("status-success", sprintf("Showing '%s' (design_id: %s).", row$title[1], did))
    })
    observeEvent(input$list_rows_selected, {
      did <- selected_id(); if (is.null(did)) return()
      load_versions(did)
    }, ignoreNULL = TRUE)

    td_actions_server(input, session, api_manager, function() current_design())

    observeEvent(input$open_editor, {
      did <- selected_id(); if (is.null(did)) return()
      api_manager$set_pending_techdesign_load(list(key = paste0("db:", did)))
      updateTabItems(session$rootScope(), "sidebar_menu", selected = "techdesign_editor")
    })

    observeEvent(input$generate_similar, {
      did <- selected_id(); if (is.null(did)) return()
      df <- filtered(); r <- df[df$design_id == did, ][1, ]
      td_goto_generate(api_manager, session, r$design_group, r$design_type)
    })

    version_row_id <- function() {
      i <- input$versions_rows_selected
      if (is.null(i) || is.null(current_id())) { showNotification("Show a design and select a version first.", type = "warning"); return(NULL) }
      v <- api_manager$bq_get_techdesign_versions(current_id())
      if (nrow(v) < i) return(NULL)
      v$id[i]
    }
    observeEvent(input$view_version, {
      rid <- version_row_id(); if (is.null(rid)) return()
      row <- api_manager$bq_get_techdesign_row(rid)
      if (nrow(row) == 0) return()
      draw(techdesign_from_row(row))
      set_status("status-info", sprintf("Showing stored version (row %s, %s). This is not yet the newest version unless you restore it.", rid, row$change_type[1]))
    })
    observeEvent(input$restore_version, {
      rid <- version_row_id(); if (is.null(rid)) return()
      row <- api_manager$bq_get_techdesign_row(rid)
      if (nrow(row) == 0) return()
      tryCatch({
        row$change_type <- "update"; row$created_by <- "restore"
        row$id <- NULL; row$created_at <- NULL
        api_manager$bq_insert_techdesign(row)
        draw(techdesign_from_row(row)); load_versions(current_id())
        set_status("status-success", sprintf("Restored row %s as the newest version.", rid))
      }, error = function(e) set_status("status-error", paste("Restore failed:", e$message)))
    })

    observeEvent(input$delete, {
      did <- selected_id(); if (is.null(did)) return()
      showModal(modalDialog(title = "Delete this design?",
        "A 'delete' version is appended and the design disappears from the lists; the history stays in BigQuery and can be restored from the table.",
        footer = tagList(modalButton("Cancel"), actionButton(session$ns("confirm_delete"), "Delete", class = "btn-danger"))))
    })
    observeEvent(input$confirm_delete, {
      removeModal()
      did <- selected_id(); if (is.null(did)) return()
      row <- api_manager$bq_get_techdesign(did)
      if (nrow(row) == 0) return()
      row$change_type <- "delete"; row$id <- NULL; row$created_at <- NULL
      tryCatch({
        api_manager$bq_insert_techdesign(row)
        set_status("status-success", "Design deleted.")
      }, error = function(e) set_status("status-error", paste("Delete failed:", e$message)))
    })

    output$status <- renderUI(tags$div())
    output$diagram <- renderUI(tags$div(class = "status-info", "Select a design and click 'Show Diagram'."))
  })
}
