# R/utils_techdesign_module.R
# Shared UI + server for the three Technical Designs subtabs. Each subtab is a
# thin wrapper (modules/Technical Designs/<id>/) that passes its group.

td_force_header <- function(text, group, design_type = NULL) {
  lines <- strsplit(gsub("\r", "", text), "\n", fixed = TRUE)[[1]]
  set_line <- function(lines, key, value) {
    idx <- grep(paste0("^\\s*", key, "\\s*:"), lines)
    # only consider the header region (before the first @block)
    first_block <- grep("^\\s*@", lines)[1]
    if (length(idx) > 0 && (is.na(first_block) || idx[1] < first_block)) { lines[idx[1]] <- paste0(key, ": ", value); lines }
    else c(paste0(key, ": ", value), lines)
  }
  if (!is.null(design_type)) lines <- set_line(lines, "design_type", design_type)
  lines <- set_line(lines, "design_group", group)
  paste(lines, collapse = "\n")
}

td_design_name <- function(group, design_type, fallback = "") {
  e <- td_catalog_entry(group, design_type)
  if (!is.null(e)) return(e$label)
  if (nzchar(fallback)) return(fallback)
  tools::toTitleCase(gsub("_", " ", design_type))
}


# ---- Shared handoff buttons (Mind Map / Flex Table) -------------------
td_actions_ui <- function(ns) {
  div(class = "td-actions",
      p(style = "color:#7f8c8d;font-size:12px;margin:4px 0 8px 0;",
        "Send the design currently shown above to another tab group:"),
      fluidRow(
        column(3, actionButton(ns("act_mindmap"), "Create Mind Map", icon = icon("project-diagram"), class = "btn-primary", style = "width:100%;margin-bottom:6px;")),
        column(3, actionButton(ns("act_flex_components"), "Components to Flex Table", icon = icon("table"), class = "btn-info", style = "width:100%;margin-bottom:6px;")),
        column(3, actionButton(ns("act_flex_tradeoffs"), "Trade-offs to Flex Table", icon = icon("balance-scale"), class = "btn-info", style = "width:100%;margin-bottom:6px;")),
        column(3, actionButton(ns("act_flex_connections"), "Connections to Flex Table", icon = icon("exchange-alt"), class = "btn-info", style = "width:100%;margin-bottom:6px;"))
      ))
}

# Call inside a moduleServer. get_design() must return a parsed design or NULL.
td_actions_server <- function(input, session, api_manager, get_design) {
  need <- function() {
    d <- get_design()
    if (is.null(d)) showNotification("Generate or load a design first.", type = "warning")
    d
  }
  observeEvent(input$act_mindmap, {
    d <- need(); if (is.null(d)) return()
    if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
    tryCatch({
      df <- techdesign_to_mindmap_df(d)
      df$change_type <- "create"
      df$category <- TD_MINDMAP_CATEGORY
      df$domain <- TD_GROUP_LABELS[[d$meta$design_group]]
      df$topic <- d$meta$title
      df$map_id <- generate_new_map_id(d$meta$title)
      df$map_title <- d$meta$title
      n <- api_manager$bq_insert_mindmap(df, source = "claude")
      api_manager$trigger_state_update_mindmap()
      showNotification(sprintf("Mind map created (%d nodes) under category '%s'. Open it in the Mind Map group.", n, TD_MINDMAP_CATEGORY),
                       type = "message", duration = 10)
    }, error = function(e) showNotification(paste("Mind map failed:", e$message), type = "error", duration = 12))
  })
  send_flex <- function(which) {
    d <- need(); if (is.null(d)) return()
    tryCatch({
      api_manager$set_pending_bulk_text_flex(techdesign_to_flex_text(d, which))
      updateTabItems(session$rootScope(), "sidebar_menu", selected = "bulk_import")
      showNotification("Sent to Flex Table's Bulk Import tab.", type = "message")
    }, error = function(e) showNotification(paste("Could not send:", e$message), type = "error"))
  }
  observeEvent(input$act_flex_components, send_flex("components"))
  observeEvent(input$act_flex_tradeoffs, send_flex("tradeoffs"))
  observeEvent(input$act_flex_connections, send_flex("connections"))
}

# Insert a parsed design as a NEW design or a new version. Returns design_id.
td_save_design <- function(api_manager, d, design_id = NULL, change_type = NULL, name = NULL) {
  exists <- !is.null(design_id)
  did <- design_id %||% generate_new_design_id(d$meta$design_type)
  row <- techdesign_to_row(d, did, name %||% td_design_name(d$meta$design_group, d$meta$design_type, d$meta$title),
                           change_type = change_type %||% (if (exists) "update" else "create"))
  api_manager$bq_insert_techdesign(row)
  did
}

techdesign_module_ui <- function(id, group) {
  ns <- NS(id)
  choices <- c(td_catalog_choices(group), "+ Custom design..." = TD_CUSTOM_VALUE)
  kind_txt <- if (TD_GROUP_DIAGRAM_KIND[[group]] == "class") "a UML class diagram" else "a swimlane architecture diagram"

  tagList(
    fluidRow(
      box(
        title = paste("Design:", TD_GROUP_LABELS[[group]]), status = "primary", solidHeader = TRUE, width = 12,
        div(class = "alert alert-info",
            tags$strong("How this works:"), sprintf(" pick a design, describe your use case, and the Editing Tool fills in the entities (boxes), relationships (arrows), flow steps, trade-offs and references. The app computes the layout and draws %s with hover highlighting, click-for-details and a step-by-step flow player. Each design is stored as ONE row in the Technical Designs table.", kind_txt)),
        fluidRow(
          column(6, selectInput(ns("design_type"), "Design: *", choices = choices)),
          column(6, conditionalPanel(
            condition = sprintf("input['%s'] == '%s'", ns("design_type"), TD_CUSTOM_VALUE),
            textInput(ns("custom_name"), "Name of the custom design: *", placeholder = "e.g., Feature Flag Rollout Architecture")))
        ),
        textAreaInput(ns("context"), "Use case / context to tailor the design to:", rows = 3, width = "100%",
                      placeholder = "e.g., A bank wants employees to ask questions over 50,000 internal policy PDFs with citations."),
        fluidRow(
          column(6, textInput(ns("constraints"), "Constraints / preferred stack (optional):",
                              placeholder = "e.g., AWS only, Postgres, no external LLM APIs")),
          column(6, textInput(ns("reference"), "Book or online resource to follow (optional):",
                              placeholder = "e.g., Designing Machine Learning Systems by Chip Huyen"))
        ),
        radioButtons(ns("detail"), "Level of detail:", inline = TRUE,
                     choices = c("Compact" = "1", "Standard" = "2", "Detailed" = "3"), selected = "2"),
        hr(),
        fluidRow(
          column(3, actionButton(ns("generate"), "Generate Design", icon = icon("magic"), class = "btn-primary btn-lg", style = "width: 100%;")),
          column(3, actionButton(ns("preview"), "Re-Parse & Draw", icon = icon("sync"), class = "btn-info btn-lg", style = "width: 100%;")),
          column(3, actionButton(ns("save"), "Save to BigQuery", icon = icon("cloud-upload-alt"), class = "btn-success btn-lg", style = "width: 100%;")),
          column(3, downloadButton(ns("download"), "Download Text", class = "btn-warning btn-lg", style = "width: 100%;"))
        ),
        br(),
        fluidRow(column(3, actionButton(ns("to_bulk"), "Send to Bulk Import", icon = icon("share-square"), class = "btn-default", style = "width: 100%;")))
      )
    ),

    fluidRow(
      box(
        title = "Generated Design Data (editable text)", status = "success", solidHeader = TRUE, width = 12, collapsible = TRUE,
        div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
            icon("spinner", class = "fa-spin fa-3x"), h4("Generating design... this can take 30-90 seconds.")),
        p(style = "color:#7f8c8d;font-size:12px;",
          "Edit anything here (a label, a connection, a trade-off), then click 'Re-Parse & Draw'. 'Save' stores exactly what is in this box; ",
          "if you loaded a saved design for editing, saving adds a NEW VERSION of it."),
        textAreaInput(ns("gen_text"), NULL, rows = 16, width = "100%",
                      placeholder = "The generated design text will appear here."),
        htmlOutput(ns("status"))
      )
    ),

    fluidRow(
      box(
        title = "Diagram", status = "info", solidHeader = TRUE, width = 12,
        export_controls_ui(ns, ns("export_target"), "technical_design"),
        uiOutput(ns("diagram"))
      )
    ),

    fluidRow(
      box(title = "Use This Design Elsewhere", status = "success", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE,
          td_actions_ui(ns))
    ),

    fluidRow(
      box(
        title = "Saved Designs", status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE,
        fluidRow(
          column(4, selectInput(ns("saved_type"), "Design type:", choices = c("All designs" = ""))),
          column(8, selectInput(ns("saved_id"), "Saved version: *", choices = c("(none saved yet)" = "")))
        ),
        fluidRow(
          column(3, actionButton(ns("load_view"), "Show Diagram", icon = icon("eye"), class = "btn-primary", style = "width: 100%;")),
          column(3, actionButton(ns("load_edit"), "Load into Editor", icon = icon("edit"), class = "btn-info", style = "width: 100%;")),
          column(3, actionButton(ns("delete"), "Delete", icon = icon("trash"), class = "btn-danger", style = "width: 100%;")),
          column(3, actionButton(ns("refresh"), "Refresh List", icon = icon("sync"), class = "btn-default", style = "width: 100%;"))
        )
      )
    ),

    fluidRow(
      box(
        title = "Browse Stored Rows", status = "warning", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE,
        p(style = "color:#7f8c8d;font-size:12px;", "Every stored version of every design in this group (append-only history)."),
        actionButton(ns("browse_refresh"), "Load Rows", icon = icon("table"), class = "btn-default"),
        br(), br(),
        DT::dataTableOutput(ns("browse_table"))
      )
    )
  )
}

techdesign_module_server <- function(id, api_manager, group) {
  moduleServer(id, function(input, output, session) {

    current_design <- reactiveVal(NULL)
    editing_id <- reactiveVal(NULL)

    set_status <- function(cls, icon_cls, msg, extra = NULL) {
      output$status <- renderUI({
        tags$div(class = cls, tags$i(class = icon_cls), " ", msg, extra)
      })
    }

    draw <- function(d) {
      current_design(d)
      output$diagram <- renderUI({ export_capture_wrapper(session$ns, render_techdesign(d), d$meta$title %||% "technical_design") })
    }

    warn_ui <- function(d) {
      if (length(d$warnings) == 0) return(NULL)
      tags$ul(style = "margin-top:6px;", lapply(d$warnings, tags$li))
    }

    chosen_type <- reactive({
      dt <- input$design_type %||% ""
      if (identical(dt, TD_CUSTOM_VALUE)) td_slug(trimws(input$custom_name %||% "")) else dt
    })
    chosen_label <- reactive({
      dt <- input$design_type %||% ""
      if (identical(dt, TD_CUSTOM_VALUE)) trimws(input$custom_name %||% "") else (td_catalog_entry(group, dt)$label %||% dt)
    })

    # ---------------- Generate ----------------
    observeEvent(input$generate, {
      if (!api_manager$claude_authenticated) {
        showNotification("Please configure and save Editing Tool API credentials first!", type = "error", duration = 10)
        return()
      }
      dt <- input$design_type %||% ""
      custom <- identical(dt, TD_CUSTOM_VALUE)
      if (custom && nchar(trimws(input$custom_name %||% "")) == 0) {
        showNotification("Please enter a name for the custom design.", type = "error"); return()
      }
      entry <- if (custom) NULL else td_catalog_entry(group, dt)

      prompt <- generate_techdesign_prompt(
        group = group, design_type = chosen_type(), design_label = chosen_label(),
        guidance = entry$guidance %||% "", context = input$context %||% "",
        constraints = input$constraints %||% "", reference = input$reference %||% "",
        detail = as.integer(input$detail %||% "2"), custom = custom
      )

      editing_id(NULL)
      shinyjs::show("loading_spinner")
      updateTextAreaInput(session, "gen_text", value = "")
      progress_msg <- reactiveVal("Sending request to the Editing Tool...")
      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " ", progress_msg()) })

      tryCatch({
        resp <- api_manager$call_claude(prompt = prompt, max_tokens = 9000, progress_callback = function(msg) progress_msg(msg))
        truncated <- identical(attr(resp, "claude_stop_reason"), "max_tokens")
        txt <- td_force_header(resp, group, chosen_type())
        updateTextAreaInput(session, "gen_text", value = txt)
        shinyjs::hide("loading_spinner")

        d <- parse_techdesign_text(txt)
        draw(d)
        if (truncated) {
          set_status("status-warning", "fa fa-exclamation-triangle",
                     "Response was cut off by the token limit. The diagram shows what was complete; consider the Compact level of detail and regenerate.", warn_ui(d))
        } else {
          set_status("status-success", "fa fa-check-circle",
                     sprintf("Generated %d components and %d connections. Review the diagram, then 'Save to BigQuery'.", nrow(d$components), nrow(d$connections)), warn_ui(d))
        }
      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        set_status("status-error", "fa fa-times-circle", paste("Failed:", e$message))
        showNotification(paste("Error:", e$message), type = "error", duration = 12)
      })
    })

    # ---------------- Handoffs ----------------
    td_actions_server(input, session, api_manager, function() current_design())

    observeEvent(input$to_bulk, {
      if (nchar(trimws(input$gen_text %||% "")) == 0) { showNotification("Nothing to send - generate a design first.", type = "warning"); return() }
      api_manager$set_pending_bulk_text_techdesign(td_force_header(input$gen_text, group))
      updateTabItems(session$rootScope(), "sidebar_menu", selected = "techdesign_bulk_import")
      showNotification("Design sent to the Technical Designs Bulk Import tab.", type = "message")
    })

    # Recommender / Guide -> this subtab: preselect the design and optionally the context
    observeEvent(api_manager$pending_techdesign_selection(), {
      sel <- api_manager$pending_techdesign_selection()
      if (is.null(sel) || !identical(sel$group, group)) return()
      if (!is.null(sel$design_type) && !is.null(td_catalog_entry(group, sel$design_type))) {
        updateSelectInput(session, "design_type", selected = sel$design_type)
      }
      if (nzchar(sel$context %||% "")) updateTextAreaInput(session, "context", value = sel$context)
      api_manager$set_pending_techdesign_selection(NULL)
      showNotification(sprintf("Preselected: %s", td_design_name(group, sel$design_type %||% "")), type = "message")
    }, ignoreInit = TRUE, ignoreNULL = TRUE)

    # ---------------- Re-parse & draw ----------------
    observeEvent(input$preview, {
      if (nchar(trimws(input$gen_text %||% "")) == 0) { showNotification("The text box is empty.", type = "warning"); return() }
      tryCatch({
        d <- parse_techdesign_text(td_force_header(input$gen_text, group))
        draw(d)
        set_status("status-success", "fa fa-check-circle",
                   sprintf("Parsed %d components, %d connections, %d steps.", nrow(d$components), nrow(d$connections), nrow(d$steps)), warn_ui(d))
      }, error = function(e) set_status("status-error", "fa fa-times-circle", paste("Parse problem:", e$message)))
    })

    # ---------------- Save ----------------
    observeEvent(input$save, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      if (nchar(trimws(input$gen_text %||% "")) == 0) { showNotification("Nothing to save - generate a design first.", type = "warning"); return() }
      tryCatch({
        eid <- editing_id()
        txt <- if (is.null(eid) && !is.null(chosen_type()) && nzchar(chosen_type())) td_force_header(input$gen_text, group, chosen_type())
               else td_force_header(input$gen_text, group)
        d <- parse_techdesign_text(txt)
        design_id <- eid %||% generate_new_design_id(d$meta$design_type)
        row <- techdesign_to_row(d, design_id, td_design_name(group, d$meta$design_type, chosen_label()),
                                 change_type = if (is.null(eid)) "create" else "update")
        api_manager$bq_insert_techdesign(row)
        editing_id(design_id)
        draw(d)
        set_status("status-success", "fa fa-check-circle",
                   sprintf("Saved '%s' (design_id: %s). It now appears under 'Saved Designs'.", d$meta$title, design_id), warn_ui(d))
        showNotification("Design saved", type = "message")
        updateSelectInput(session, "saved_type", selected = "")
      }, error = function(e) {
        set_status("status-error", "fa fa-times-circle", paste("Save failed:", e$message))
        showNotification(paste("Error:", e$message), type = "error", duration = 12)
      })
    })

    output$download <- downloadHandler(
      filename = function() paste0(td_slug(chosen_type() %||% "design"), "_", format(Sys.Date(), "%Y%m%d"), ".txt"),
      content = function(file) writeLines(input$gen_text %||% "", file)
    )

    # ---------------- Saved designs list ----------------
    saved_list <- reactive({
      api_manager$state_trigger_techdesign()
      input$refresh
      if (!api_manager$bq_authenticated) return(data.frame())
      api_manager$bq_get_techdesign_list(group)
    })

    observe({
      lst <- saved_list()
      if (nrow(lst) == 0) {
        updateSelectInput(session, "saved_type", choices = c("All designs" = ""))
        return()
      }
      types <- unique(lst$design_type)
      labels <- vapply(types, function(t) td_design_name(group, t, lst$name[match(t, lst$design_type)]), character(1))
      cur <- isolate(input$saved_type)
      updateSelectInput(session, "saved_type", choices = c("All designs" = "", setNames(types, labels)),
                        selected = if (!is.null(cur) && cur %in% types) cur else "")
    })

    observe({
      lst <- saved_list()
      ty <- input$saved_type %||% ""
      if (nrow(lst) > 0 && nzchar(ty)) lst <- lst[lst$design_type == ty, , drop = FALSE]
      if (nrow(lst) == 0) {
        updateSelectInput(session, "saved_id", choices = c("(none saved yet)" = ""))
        return()
      }
      lbl <- sprintf("%s%s  [%s]", lst$title, ifelse(is.na(lst$variant) | lst$variant == "", "", paste0(" - ", lst$variant)),
                     format(lst$created_at, "%Y-%m-%d %H:%M"))
      cur <- isolate(input$saved_id)
      updateSelectInput(session, "saved_id", choices = setNames(lst$design_id, lbl),
                        selected = if (!is.null(cur) && cur %in% lst$design_id) cur else lst$design_id[1])
    })

    fetch_selected <- function() {
      sid <- input$saved_id %||% ""
      if (!nzchar(sid)) { showNotification("Select a saved design first.", type = "warning"); return(NULL) }
      row <- api_manager$bq_get_techdesign(sid)
      if (nrow(row) == 0) { showNotification("Could not load that design.", type = "error"); return(NULL) }
      list(row = row, design = techdesign_from_row(row), id = sid)
    }

    observeEvent(input$load_view, {
      sel <- fetch_selected(); if (is.null(sel)) return()
      draw(sel$design)
      set_status("status-success", "fa fa-check-circle", sprintf("Showing saved design '%s'.", sel$design$meta$title))
    })

    observeEvent(input$load_edit, {
      sel <- fetch_selected(); if (is.null(sel)) return()
      updateTextAreaInput(session, "gen_text", value = techdesign_to_text(sel$design))
      editing_id(sel$id)
      draw(sel$design)
      set_status("status-info", "fa fa-info-circle", "Loaded into the editor. Saving now adds a NEW VERSION of this same design.")
    })

    observeEvent(input$delete, {
      sid <- input$saved_id %||% ""
      if (!nzchar(sid)) { showNotification("Select a saved design first.", type = "warning"); return() }
      showModal(modalDialog(
        title = "Delete this design?",
        "It will be hidden from the lists (a 'delete' version is appended; nothing is physically removed from BigQuery).",
        footer = tagList(modalButton("Cancel"), actionButton(session$ns("confirm_delete"), "Delete", class = "btn-danger"))
      ))
    })
    observeEvent(input$confirm_delete, {
      removeModal()
      sid <- input$saved_id %||% ""
      row <- api_manager$bq_get_techdesign(sid)
      if (nrow(row) == 0) return()
      row$change_type <- "delete"; row$id <- NULL; row$created_at <- NULL
      tryCatch({
        api_manager$bq_insert_techdesign(row)
        showNotification("Design deleted.", type = "message")
      }, error = function(e) showNotification(paste("Error:", e$message), type = "error"))
    })

    # ---------------- Browse ----------------
    observeEvent(input$browse_refresh, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      df <- tryCatch(api_manager$bq_query(sprintf(
        "SELECT id, created_at, design_id, design_type, title, variant, change_type, complexity_level, diagram_kind, schema_version, created_by
         FROM `%s` WHERE design_group = '%s' ORDER BY id DESC LIMIT 300", api_manager$bq_full_table_techdesign, group)),
        error = function(e) { showNotification(paste("Error:", e$message), type = "error"); data.frame() })
      output$browse_table <- DT::renderDataTable(DT::datatable(df, options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE))
    })

    output$status <- renderUI({ tags$div() })
    output$diagram <- renderUI({ tags$div(class = "status-info", "Generate or load a design to see its diagram here.") })
    session$onSessionEnded(function() {})
  })
}
