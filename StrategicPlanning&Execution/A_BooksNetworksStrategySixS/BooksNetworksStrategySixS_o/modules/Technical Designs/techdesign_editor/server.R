# modules/Technical Designs/techdesign_editor/server.R

techdesign_editor_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    keys <- c("components", "connections", "steps", "tradeoffs", "references")
    rv <- reactiveValues(group = NULL, kind = "layered", edit_id = NULL, undo = NULL, loaded = FALSE,
                         components = NULL, connections = NULL, steps = NULL, tradeoffs = NULL, references = NULL,
                         ver_components = 0, ver_connections = 0, ver_steps = 0, ver_tradeoffs = 0, ver_references = 0)
    set_status <- function(cls, msg) output$status <- renderUI(tags$div(class = cls, msg))

    # ---------- source list ----------
    observe({
      api_manager$state_trigger_techdesign()
      ch <- td_design_choices(api_manager)
      if (length(ch) == 0) ch <- c("(no designs available)" = "")
      cur <- isolate(input$source)
      updateSelectInput(session, "source", choices = ch, selected = if (!is.null(cur) && cur %in% ch) cur else ch[1])
    })

    # ---------- state load / snapshot ----------
    set_state <- function(d, edit_id = NULL) {
      rv$group <- d$meta$design_group; rv$kind <- d$meta$diagram_kind; rv$edit_id <- edit_id; rv$loaded <- TRUE
      for (k in keys) { rv[[k]] <- as.data.frame(d[[k]], stringsAsFactors = FALSE); rv[[paste0("ver_", k)]] <- rv[[paste0("ver_", k)]] + 1 }
      updateTextInput(session, "m_title", value = d$meta$title)
      updateTextInput(session, "m_variant", value = d$meta$variant)
      updateSelectInput(session, "m_complexity", selected = if (d$meta$complexity %in% c("Low", "Medium", "High")) d$meta$complexity else "Medium")
      updateTextInput(session, "m_type", value = d$meta$design_type)
      updateTextAreaInput(session, "m_summary", value = d$meta$summary)
      updateTextAreaInput(session, "m_when", value = d$meta$when_to_use)
      updateTextAreaInput(session, "m_when_not", value = d$meta$when_not_to_use)
      updateTextInput(session, "m_tags", value = d$meta$tags)
    }

    snapshot_text <- function() {
      meta <- list(design_id = "", design_group = rv$group, design_type = td_slug(input$m_type %||% "custom"),
                   title = input$m_title %||% "", variant = input$m_variant %||% "", summary = input$m_summary %||% "",
                   when_to_use = input$m_when %||% "", when_not_to_use = input$m_when_not %||% "",
                   complexity = input$m_complexity %||% "Medium", tags = input$m_tags %||% "", diagram_kind = rv$kind)
      techdesign_to_text(list(meta = meta, components = rv$components, connections = rv$connections, steps = rv$steps,
                              tradeoffs = rv$tradeoffs, references = rv$references))
    }

    current <- reactive({
      req(rv$loaded)
      # take dependencies on all editable state
      for (k in keys) rv[[k]]
      txt <- snapshot_text()
      tryCatch(parse_techdesign_text(txt), error = function(e) e)
    })
    current_d <- debounce(current, 700)

    observeEvent(input$load, {
      key <- input$source %||% ""
      d <- td_load_design(api_manager, key)
      if (is.null(d)) { showNotification("Could not load that design.", type = "error"); return() }
      eid <- if (startsWith(key, "db:")) sub("^db:", "", key) else NULL
      set_state(d, eid)
      set_status("status-info", if (is.null(eid)) "Loaded a starter design. 'Save as New Version' will create it as a new saved design; 'Save as Copy' also works."
                                else sprintf("Loaded saved design %s. 'Save as New Version' appends a version to it.", eid))
    })

    observeEvent(input$blank, {
      g <- input$blank_group
      blank <- if (TD_GROUP_DIAGRAM_KIND[[g]] == "class") {
        parse_techdesign_text(paste(c(paste0("design_group: ", g), "design_type: custom_design", "title: New design", "variant: N/A",
          "summary: Describe the design.", "when_to_use: N/A", "when_not_to_use: N/A", "complexity: Medium", "tags: N/A", "",
          "@component", "id: C1", "label: Interface", "lane: Abstractions", "kind: interface", "description: Contract.", "attributes: N/A", "methods: + run(): void", "",
          "@component", "id: C2", "label: Implementation", "lane: Concrete Classes", "kind: class", "description: Does the work.", "attributes: N/A", "methods: + run(): void", "",
          "@connection", "from: C2", "to: C1", "label: implements", "type: implements"), collapse = "\n"))
      } else {
        parse_techdesign_text(paste(c(paste0("design_group: ", g), "design_type: custom_design", "title: New design", "variant: N/A",
          "summary: Describe the design.", "when_to_use: N/A", "when_not_to_use: N/A", "complexity: Medium", "tags: N/A", "",
          "@component", "id: C1", "label: Source", "lane: Inputs", "kind: external", "description: Where data comes from.", "technologies: N/A", "",
          "@component", "id: C2", "label: Processor", "lane: Processing", "kind: process", "description: Transforms the data.", "technologies: N/A", "",
          "@connection", "from: C1", "to: C2", "label: data", "type: data"), collapse = "\n"))
      }
      set_state(blank, NULL)
      set_status("status-info", "Blank design created. Edit the tables, then save.")
    })

    # Library -> Editor handoff
    observeEvent(api_manager$pending_techdesign_load(), {
      x <- api_manager$pending_techdesign_load()
      if (is.null(x) || is.null(x$key)) return()
      d <- td_load_design(api_manager, x$key)
      api_manager$set_pending_techdesign_load(NULL)
      if (is.null(d)) { showNotification("Could not load that design.", type = "error"); return() }
      set_state(d, if (startsWith(x$key, "db:")) sub("^db:", "", x$key) else NULL)
      set_status("status-info", "Loaded from the Design Library.")
    }, ignoreInit = TRUE, ignoreNULL = TRUE)

    # ---------- live diagram ----------
    output$diagram <- renderUI({
      if (!isTRUE(rv$loaded)) return(tags$div(class = "status-info", "Load a design or start a blank one."))
      d <- current_d()
      if (inherits(d, "error")) return(tags$div(class = "status-error", "Cannot draw yet: ", conditionMessage(d)))
      tagList(if (length(d$warnings) > 0) tags$div(class = "status-warning", tags$ul(lapply(d$warnings, tags$li))),
              export_capture_wrapper(session$ns, render_techdesign(d), d$meta$title))
    })

    # ---------- editable tables ----------
    for (k in keys) local({
      key <- k
      output[[paste0("tbl_", key)]] <- DT::renderDataTable({
        rv[[paste0("ver_", key)]]
        df <- isolate(rv[[key]])
        if (is.null(df)) return(NULL)
        DT::datatable(df, rownames = FALSE, editable = list(target = "cell", disable = list(columns = NULL)), selection = "single",
                      options = list(dom = "t", paging = FALSE, scrollX = TRUE, scrollY = "300px", scrollCollapse = TRUE))
      })
      observeEvent(input[[paste0("tbl_", key, "_cell_edit")]], {
        info <- input[[paste0("tbl_", key, "_cell_edit")]]
        df <- rv[[key]]
        i <- info$row; j <- info$col + 1L
        if (i <= nrow(df) && j <= ncol(df)) { df[i, j] <- as.character(info$value); rv[[key]] <- df }
      })
      observeEvent(input[[paste0("add_", key)]], {
        df <- rv[[key]]; if (is.null(df)) return()
        new <- as.data.frame(setNames(as.list(rep("", ncol(df))), names(df)), stringsAsFactors = FALSE)
        if (key == "components") {
          n <- nrow(df) + 1L; while (paste0("C", n) %in% df$id) n <- n + 1L
          new$id <- paste0("C", n); new$label <- "New component"; new$lane <- if (nrow(df)) df$lane[nrow(df)] else "Lane"
          new$kind <- if (rv$kind == "class") "class" else "process"
        } else if (key == "connections") {
          new$from <- if (nrow(rv$components)) rv$components$id[1] else ""; new$to <- if (nrow(rv$components) > 1) rv$components$id[2] else ""
          new$type <- if (rv$kind == "class") "uses" else "data"; new$label <- "new link"
        } else if (key == "steps") { new$order <- as.character(nrow(df) + 1L); new$text <- "New step" }
        else if (key == "tradeoffs") { new$kind <- "pro"; new$text <- "New point" }
        else if (key == "references") new$title <- "New reference"
        rv[[key]] <- rbind(df, new); rv[[paste0("ver_", key)]] <- rv[[paste0("ver_", key)]] + 1
      })
      observeEvent(input[[paste0("del_", key)]], {
        i <- input[[paste0("tbl_", key, "_rows_selected")]]
        if (is.null(i)) { showNotification("Select a row first.", type = "warning"); return() }
        df <- rv[[key]]; df <- df[-i, , drop = FALSE]; rownames(df) <- NULL
        if (key == "components") {
          gone <- rv$components$id[i]
          cn <- rv$connections; rv$connections <- cn[!(cn$from %in% gone | cn$to %in% gone), , drop = FALSE]
          rv$ver_connections <- rv$ver_connections + 1
        }
        if (key == "steps" && nrow(df) > 0) df$order <- as.character(seq_len(nrow(df)))
        rv[[key]] <- df; rv[[paste0("ver_", key)]] <- rv[[paste0("ver_", key)]] + 1
      })
    })

    # ---------- Claude modify ----------
    observeEvent(input$modify, {
      if (!isTRUE(rv$loaded)) { showNotification("Load a design first.", type = "warning"); return() }
      if (!api_manager$claude_authenticated) { showNotification("Please configure and save the API credentials first!", type = "error"); return() }
      if (nchar(trimws(input$instruction %||% "")) < 5) { showNotification("Describe the change you want.", type = "warning"); return() }
      set_status("status-info", tags$span(tags$i(class = "fa fa-spinner fa-spin"), " The Editing Tool is modifying the design..."))
      tryCatch({
        before <- snapshot_text()
        resp <- api_manager$call_claude(prompt = generate_td_modify_prompt(before, input$instruction), max_tokens = 9000, progress_callback = function(m) NULL)
        txt <- td_force_header(td_strip_fences(resp), rv$group)
        d <- parse_techdesign_text(txt)
        rv$undo <- before
        set_state(d, rv$edit_id)
        set_status("status-success", sprintf("The Editing Tool updated the design (%d components, %d connections). Review it, then save.", nrow(d$components), nrow(d$connections)))
      }, error = function(e) set_status("status-error", paste("Editing Tool change failed:", e$message)))
    })
    observeEvent(input$undo, {
      if (is.null(rv$undo)) { showNotification("Nothing to undo.", type = "warning"); return() }
      d <- parse_techdesign_text(rv$undo); rv$undo <- NULL
      set_state(d, rv$edit_id); set_status("status-info", "Reverted the last Editing Tool change.")
    })

    # ---------- Save ----------
    do_save <- function(as_copy) {
      if (!isTRUE(rv$loaded)) { showNotification("Load a design first.", type = "warning"); return() }
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      tryCatch({
        d <- parse_techdesign_text(snapshot_text())
        eid <- if (as_copy) NULL else rv$edit_id
        did <- td_save_design(api_manager, d, design_id = eid)
        rv$edit_id <- did
        set_status("status-success", sprintf("Saved '%s' as %s (design_id: %s).", d$meta$title,
                                             if (is.null(eid)) "a new design" else "a new version", did))
        showNotification("Design saved", type = "message")
      }, error = function(e) set_status("status-error", paste("Save failed:", e$message)))
    }
    observeEvent(input$save_version, do_save(FALSE))
    observeEvent(input$save_copy, do_save(TRUE))

    output$download <- downloadHandler(
      filename = function() paste0(td_slug(input$m_type %||% "design"), "_", format(Sys.Date(), "%Y%m%d"), ".txt"),
      content = function(file) writeLines(if (isTRUE(rv$loaded)) snapshot_text() else "", file))

    td_actions_server(input, session, api_manager, function() {
      if (!isTRUE(rv$loaded)) return(NULL)
      d <- tryCatch(parse_techdesign_text(snapshot_text()), error = function(e) NULL); d
    })

    output$status <- renderUI(tags$div())
  })
}
