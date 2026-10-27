# modules/Technical Designs/techdesign_matrix/server.R

techdesign_matrix_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    current <- reactiveVal(NULL)
    editing_id <- reactiveVal(NULL)

    set_status <- function(cls, icon_cls, msg, extra = NULL) {
      output$status <- renderUI(tags$div(class = cls, style = "margin-top:10px;", tags$i(class = icon_cls), " ", msg, extra))
    }
    warn_ui <- function(d) if (length(d$warnings) == 0) NULL else tags$ul(style = "margin-top:6px;", lapply(d$warnings, tags$li))
    summary_msg <- function(d) {
      cnt <- tdm_status_counts(d)
      sprintf("%d rows x %d columns. Evidence: %d verified, %d unverified, %d contradicted, %d judgment, %d source(s).",
              nrow(d$rows), nrow(d$cols), cnt[["verified"]], cnt[["unverified"]], cnt[["contradicted"]], cnt[["judgment"]], nrow(d$sources))
    }

    draw <- function(d) {
      current(d)
      output$diagram <- renderUI(export_capture_wrapper(session$ns, render_matrix(d), d$meta$title %||% "market_matrix"))
      output$evidence <- DT::renderDataTable(DT::datatable(tdm_cells_table(d), rownames = FALSE, filter = "top",
                                                           options = list(pageLength = 15, scrollX = TRUE)))
    }
    show_text <- function(d) updateTextAreaInput(session, "gen_text", value = matrix_to_text(d))

    # ---- Example shown on first open (no API needed)
    load_seed <- function(path) {
      d <- parse_matrix_text(paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n"))
      editing_id(NULL); show_text(d); draw(d)
      set_status("status-info", "fa fa-info-circle", paste("Example loaded (illustrative judgments, no sources).", summary_msg(d)), warn_ui(d))
    }
    observeEvent(TRUE, {
      f <- tdm_seed_files()
      if (length(f) > 0) tryCatch(load_seed(f[[1]]), error = function(e) NULL)
    }, once = TRUE)
    observeEvent(input$load_seed, {
      sd <- input$seed %||% ""
      if (!nzchar(sd) || !file.exists(sd)) { showNotification("No example selected.", type = "warning"); return() }
      tryCatch(load_seed(sd), error = function(e) showNotification(paste("Could not load the example:", e$message), type = "error"))
    })

    # ---- Generate (plan -> research per column -> verify -> hierarchies -> names)
    observeEvent(input$generate, {
      if (!api_manager$claude_authenticated) {
        showNotification("Please configure and save Editing Tool API credentials first!", type = "error", duration = 10); return()
      }
      topic <- trimws(input$topic %||% "")
      if (nchar(topic) < 10) { showNotification("Please describe what should be contrasted (at least a sentence).", type = "warning"); return() }
      research <- identical(input$research, "web")
      editing_id(NULL)
      run <- function(prog) {
        tdm_run_pipeline(api_manager, topic, n_rows = input$n_rows %||% 14, n_cols = input$n_cols %||% 8,
                         tree_mode = input$tree_mode %||% "computed", research = research, max_uses = input$max_uses %||% 4,
                         verify = isTRUE(input$verify), extra = input$extra %||% "", progress = prog)
      }
      tryCatch({
        d <- withProgress(message = "Generating matrix", value = 0.1, {
          run(function(m) { cat("[Market Matrix]", m, "\n"); setProgress(detail = m) })
        })
        show_text(d); draw(d)
        set_status(if (length(d$warnings) > 0) "status-warning" else "status-success", "fa fa-check-circle",
                   paste(summary_msg(d), "Review it, then 'Save to BigQuery'."), warn_ui(d))
      }, error = function(e) {
        set_status("status-error", "fa fa-times-circle", paste("Failed:", e$message))
        showNotification(paste("Error:", e$message), type = "error", duration = 12)
      })
    })

    observeEvent(input$preview, {
      if (nchar(trimws(input$gen_text %||% "")) == 0) { showNotification("The text box is empty.", type = "warning"); return() }
      tryCatch({
        d <- parse_matrix_text(input$gen_text); draw(d)
        set_status("status-success", "fa fa-check-circle", summary_msg(d), warn_ui(d))
      }, error = function(e) set_status("status-error", "fa fa-times-circle", paste("Parse problem:", e$message)))
    })

    observeEvent(input$rename, {
      d <- current()
      if (is.null(d)) { showNotification("Generate or load a matrix first.", type = "warning"); return() }
      if (!api_manager$claude_authenticated) { showNotification("Please configure the Editing Tool API credentials first!", type = "error"); return() }
      tryCatch({
        d <- withProgress(message = "Naming branches", value = 0.3, tdm_rename_branches(api_manager, d))
        show_text(d); draw(d)
        set_status("status-success", "fa fa-check-circle", "Branches renamed.")
      }, error = function(e) set_status("status-error", "fa fa-times-circle", paste("Could not name the branches:", e$message)))
    })

    # ---- Save
    observeEvent(input$save, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      if (nchar(trimws(input$gen_text %||% "")) == 0) { showNotification("Nothing to save - generate a matrix first.", type = "warning"); return() }
      tryCatch({
        d <- parse_matrix_text(input$gen_text)
        eid <- editing_id()
        did <- eid %||% generate_new_design_id("market_matrix")
        api_manager$bq_insert_techdesign(tdm_to_row(d, did, d$meta$title, change_type = if (is.null(eid)) "create" else "update"))
        editing_id(did); draw(d)
        set_status("status-success", "fa fa-check-circle", sprintf("Saved '%s' (design_id: %s).", d$meta$title, did), warn_ui(d))
        showNotification("Matrix saved", type = "message")
      }, error = function(e) {
        set_status("status-error", "fa fa-times-circle", paste("Save failed:", e$message))
        showNotification(paste("Error:", e$message), type = "error", duration = 12)
      })
    })

    # ---- Downloads and handoff
    output$dl_json <- downloadHandler(filename = function() paste0("market_matrix_", format(Sys.Date(), "%Y%m%d"), ".json"),
                                      content = function(file) writeLines(input$gen_text %||% "", file, useBytes = TRUE))
    output$dl_csv <- downloadHandler(filename = function() paste0("market_matrix_evidence_", format(Sys.Date(), "%Y%m%d"), ".csv"),
                                     content = function(file) { d <- current(); utils::write.csv(if (is.null(d)) data.frame() else tdm_cells_table(d), file, row.names = FALSE) })
    observeEvent(input$to_flex, {
      d <- current(); if (is.null(d)) { showNotification("Generate or load a matrix first.", type = "warning"); return() }
      tryCatch({
        api_manager$set_pending_bulk_text_flex(tdm_to_flex_text(d))
        updateTabItems(session$rootScope(), "sidebar_menu", selected = "bulk_import")
        showNotification("Sent to Flex Table's Bulk Import tab.", type = "message")
      }, error = function(e) showNotification(paste("Could not send:", e$message), type = "error"))
    })

    # ---- Saved matrices
    saved_list <- reactive({
      api_manager$state_trigger_techdesign(); input$refresh
      if (!api_manager$bq_authenticated) return(data.frame())
      api_manager$bq_get_techdesign_list(TDM_GROUP)
    })
    observe({
      lst <- saved_list()
      if (nrow(lst) == 0) { updateSelectInput(session, "saved_id", choices = c("(none saved yet)" = "")); return() }
      lbl <- sprintf("%s  [%s]", lst$title, format(lst$created_at, "%Y-%m-%d %H:%M"))
      cur <- isolate(input$saved_id)
      updateSelectInput(session, "saved_id", choices = setNames(lst$design_id, lbl), selected = if (!is.null(cur) && cur %in% lst$design_id) cur else lst$design_id[1])
    })
    fetch_selected <- function() {
      sid <- input$saved_id %||% ""
      if (!nzchar(sid)) { showNotification("Select a saved matrix first.", type = "warning"); return(NULL) }
      row <- api_manager$bq_get_techdesign(sid)
      if (nrow(row) == 0) { showNotification("Could not load that matrix.", type = "error"); return(NULL) }
      list(row = row, design = matrix_from_row(row), id = sid)
    }
    observeEvent(input$load_view, {
      sel <- fetch_selected(); if (is.null(sel)) return()
      draw(sel$design); set_status("status-success", "fa fa-check-circle", paste0("Showing saved matrix '", sel$design$meta$title, "'. ", summary_msg(sel$design)))
    })
    observeEvent(input$load_edit, {
      sel <- fetch_selected(); if (is.null(sel)) return()
      show_text(sel$design); editing_id(sel$id); draw(sel$design)
      set_status("status-info", "fa fa-info-circle", "Loaded into the editor. Saving now adds a NEW VERSION of this same matrix.")
    })
    observeEvent(input$delete, {
      if (!nzchar(input$saved_id %||% "")) { showNotification("Select a saved matrix first.", type = "warning"); return() }
      showModal(modalDialog(title = "Delete this matrix?",
                            "It will be hidden from the lists (a 'delete' version is appended; nothing is physically removed from BigQuery).",
                            footer = tagList(modalButton("Cancel"), actionButton(session$ns("confirm_delete"), "Delete", class = "btn-danger"))))
    })
    observeEvent(input$confirm_delete, {
      removeModal()
      row <- api_manager$bq_get_techdesign(input$saved_id %||% "")
      if (nrow(row) == 0) return()
      row$change_type <- "delete"; row$id <- NULL; row$created_at <- NULL
      tryCatch({ api_manager$bq_insert_techdesign(row); showNotification("Matrix deleted.", type = "message") },
               error = function(e) showNotification(paste("Error:", e$message), type = "error"))
    })

    output$status <- renderUI(tags$div())
    output$diagram <- renderUI(tags$div(class = "status-info", "Generate or load a matrix to see the diagram here."))
  })
}
