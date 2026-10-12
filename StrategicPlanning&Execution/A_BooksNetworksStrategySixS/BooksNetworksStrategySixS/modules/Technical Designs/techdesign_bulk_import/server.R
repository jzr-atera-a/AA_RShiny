# modules/Technical Designs/techdesign_bulk_import/server.R

techdesign_bulk_import_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed <- reactiveVal(NULL)   # list of list(d, text, error)

    observeEvent(api_manager$pending_bulk_text_techdesign(), {
      t <- api_manager$pending_bulk_text_techdesign()
      if (nchar(t) > 0) updateTextAreaInput(session, "text", value = t)
    }, ignoreInit = TRUE)

    observeEvent(input$clear, { updateTextAreaInput(session, "text", value = ""); parsed(NULL) })

    observeEvent(input$file, {
      f <- input$file
      if (!is.null(f)) updateTextAreaInput(session, "text", value = paste(readLines(f$datapath, warn = FALSE), collapse = "\n"))
    })

    observeEvent(input$load_seeds, {
      seeds <- td_seed_texts()
      if (length(seeds) == 0) { showNotification("The starter library folder (seed/techdesign) was not found next to app.R.", type = "error"); return() }
      updateTextAreaInput(session, "text", value = paste(unlist(seeds), collapse = "\n\n=====\n\n"))
      showNotification(sprintf("Loaded %d starter designs. Click 'Parse & Validate', then 'Upload'.", length(seeds)), type = "message")
    })

    existing_ids <- function() {
      if (!api_manager$bq_authenticated) return(character(0))
      lst <- api_manager$bq_get_techdesign_list()
      if (nrow(lst) == 0) character(0) else lst$design_id
    }

    do_parse <- function() {
      docs <- td_split_designs(input$text %||% "")
      if (length(docs) == 0) { showNotification("Nothing to parse.", type = "warning"); return(NULL) }
      ex <- existing_ids()
      out <- lapply(seq_along(docs), function(i) {
        d <- tryCatch(parse_techdesign_text(docs[[i]]), error = function(e) e)
        if (inherits(d, "error")) return(list(d = NULL, error = conditionMessage(d), design_id = NA_character_, idx = i))
        did <- if (nzchar(d$meta$design_id)) d$meta$design_id else NA_character_
        list(d = d, error = "", design_id = did, idx = i, exists = !is.na(did) && did %in% ex)
      })
      parsed(out)
      out
    }

    observeEvent(input$parse, {
      out <- do_parse(); if (is.null(out)) return()
      ok <- sum(vapply(out, function(x) !is.null(x$d), TRUE))
      output$status <- renderUI(tags$div(class = if (ok == length(out)) "status-success" else "status-warning",
                                         tags$i(class = "fa fa-check-circle"), sprintf(" %d design(s) found, %d valid.", length(out), ok)))
    })

    output$preview <- DT::renderDataTable({
      out <- parsed()
      if (is.null(out)) return(NULL)
      df <- do.call(rbind, lapply(out, function(x) {
        if (is.null(x$d)) return(data.frame(`#` = x$idx, design_id = "", group = "", type = "", title = "", components = NA, connections = NA,
                                            status = paste("ERROR:", x$error), check.names = FALSE, stringsAsFactors = FALSE))
        d <- x$d
        st <- if (isTRUE(x$exists)) (if (isTRUE(input$as_version)) "exists - will add new version" else "exists - will be skipped") else "new"
        if (length(d$warnings) > 0) st <- paste0(st, "; ", length(d$warnings), " warning(s): ", paste(utils::head(d$warnings, 2), collapse = " / "))
        data.frame(`#` = x$idx, design_id = x$design_id %||% "(auto)", group = d$meta$design_group, type = d$meta$design_type, title = d$meta$title,
                   components = nrow(d$components), connections = nrow(d$connections), status = st, check.names = FALSE, stringsAsFactors = FALSE)
      }))
      DT::datatable(df, rownames = FALSE, options = list(pageLength = 15, scrollX = TRUE, dom = "tp"))
    })

    observeEvent(input$upload, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      out <- do_parse(); if (is.null(out)) return()
      ex <- existing_ids()
      rows <- list(); skipped <- 0L; failed <- 0L
      stamp <- format(Sys.time(), "%Y%m%d%H%M%S")
      for (x in out) {
        if (is.null(x$d)) { failed <- failed + 1L; next }
        d <- x$d
        did <- if (!is.na(x$design_id)) x$design_id else paste0(td_slug(d$meta$design_type), "-", stamp, "-", x$idx)
        is_existing <- did %in% ex
        if (is_existing && !isTRUE(input$as_version)) { skipped <- skipped + 1L; next }
        rows[[length(rows) + 1]] <- techdesign_to_row(
          d, did, td_design_name(d$meta$design_group, d$meta$design_type, d$meta$title),
          change_type = if (is_existing) "update" else "create", created_by = "bulk_import")
      }
      if (length(rows) == 0) {
        output$status <- renderUI(tags$div(class = "status-warning", sprintf("Nothing uploaded: %d skipped (already exist), %d invalid.", skipped, failed)))
        return()
      }
      tryCatch({
        api_manager$bq_insert_techdesign(do.call(rbind, rows))
        output$status <- renderUI(tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                                           sprintf(" Uploaded %d design(s); %d skipped (already exist); %d invalid.", length(rows), skipped, failed)))
        showNotification(sprintf("Uploaded %d design(s).", length(rows)), type = "message")
        parsed(NULL)
      }, error = function(e) {
        output$status <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Upload failed: ", e$message))
      })
    })

    output$status <- renderUI(tags$div())
  })
}
