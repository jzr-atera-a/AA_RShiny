# R/utils_suite_tabs.R
# ============================================================
# Sub-tabs that several suites have in the same form are written ONCE here; each suite's file
# (modules/<Tab group>/<id>.R) only says what is different for it: titles, texts, table and functions.
#
#   raw_browse_*          "Browse and Download" of one table as stored          (Book Summary, Flex Table, Mind Map, Knowledge Graph)
#   catalog_browse_*      catalogue (one row per diagram) + its raw rows        (Strategic Analysis, Six Sigma Analysis, Sankey Graph)
#   component_import_*    paste text -> parse -> preview -> upload              (Strategic Analysis, Six Sigma Analysis)
#   tool_recommender_*    describe a problem -> ranked tools -> jump to Generate (Strategic Analysis, Six Sigma Analysis)
#
# Input and output ids are the ones each tab always had, so links between tabs and saved habits keep working.
# ============================================================

# ---- small helpers used by the shared tabs ------------------------------------------------------

# The coloured one-line status box used all over the app. kind = "info" | "success" | "warning" | "error" | "busy".
status_box <- function(kind, ...) {
  ico <- switch(kind, success = "fa fa-check-circle", warning = "fa fa-exclamation-triangle", error = "fa fa-times-circle",
                busy = "fa fa-spinner fa-spin", NULL)
  cls <- paste0("status-", if (identical(kind, "busy")) "info" else kind)
  tags$div(class = cls, if (!is.null(ico)) tags$i(class = ico), ...)
}

# A row limit typed by the user, made safe for "LIMIT %d": whole number between 1 and `max` (blank or nonsense -> default).
safe_limit <- function(x, default = 100L, max = 5000L) {
  n <- suppressWarnings(as.integer(x))
  if (length(n) != 1 || is.na(n) || n < 1L) return(as.integer(default))
  min(n, as.integer(max))
}

bq_required <- function(api_manager) {
  if (isTRUE(api_manager$bq_authenticated)) return(TRUE)
  showNotification("Please authenticate with BigQuery first!", type = "error")
  FALSE
}

csv_download <- function(prefix, data) downloadHandler(
  filename = function() paste0(prefix, "_", format(Sys.Date(), "%Y%m%d"), ".csv"),
  content = function(file) if (!is.null(data())) write.csv(data(), file, row.names = FALSE)
)

# ---- raw_browse: one table exactly as stored ------------------------------------------------------
# cfg: title, note (optional tags shown under the title), max_rows = c(value, max), table (api_manager field with the full
#      table name), file_prefix (download name)
raw_browse_ui <- function(id, cfg) {
  ns <- NS(id)
  tagList(fluidRow(
    box(title = cfg$title, status = "primary", solidHeader = TRUE, width = 12,
        cfg$note,
        fluidRow(
          column(3, actionButton(ns("refresh"), "Refresh Data", class = "btn-primary", icon = icon("sync"))),
          column(3, downloadButton(ns("download"), "Download CSV", class = "btn-info")),
          column(6, numericInput(ns("max_rows"), "Max Rows to Display:", value = cfg$max_rows[1], min = 10, max = cfg$max_rows[2], step = 10))
        ),
        br(), htmlOutput(ns("status")), br(),
        DT::dataTableOutput(ns("table")))
  ))
}

raw_browse_server <- function(id, api_manager, cfg) {
  moduleServer(id, function(input, output, session) {
    browse_data <- reactiveVal(NULL)

    observeEvent(input$refresh, {
      if (!bq_required(api_manager)) return()
      output$status <- renderUI(status_box("busy", " Loading data..."))
      tryCatch({
        data <- api_manager$bq_query(sprintf("SELECT * FROM `%s` ORDER BY created_at DESC LIMIT %d",
                                             api_manager[[cfg$table]], safe_limit(input$max_rows, cfg$max_rows[1], cfg$max_rows[2])))
        browse_data(data)
        output$table <- DT::renderDataTable(DT::datatable(data, options = list(pageLength = 25, scrollX = TRUE), rownames = FALSE))
        output$status <- renderUI(status_box("success", sprintf(" Loaded %d rows", nrow(data))))
        showNotification(sprintf("✓ Loaded %d rows", nrow(data)), type = "message")
      }, error = function(e) {
        output$status <- renderUI(status_box("error", " Error: ", app_err_text(e)))
        showNotification(paste("Error:", app_err_text(e)), type = "error")
      })
    })

    output$download <- csv_download(cfg$file_prefix, browse_data)
    output$status <- renderUI(tags$div())
    output$table <- DT::renderDataTable({})
  })
}

# ---- catalog_browse: one row per saved diagram, plus its raw rows -----------------------------------
# cfg: catalog_title, id_noun ("Diagram ID"), rows_title, rows_download ("Download Components CSV"), filter_input (input id),
#      table (api_manager field), cache (api_manager cache field), taxonomy (api_manager method), id_col, order_by (when filtered),
#      loaded (sprintf pattern with two %d), file_catalog, file_rows
catalog_browse_ui <- function(id, cfg) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = cfg$catalog_title, status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, actionButton(ns("refresh"), "Refresh Data", class = "btn-primary", icon = icon("sync"))),
            column(3, downloadButton(ns("download_catalog"), "Download Catalog CSV", class = "btn-info")),
            column(6, p(sprintf("Copy a %s below and paste it into the Visualizations tab to render it.", cfg$id_noun)))
          ),
          br(), htmlOutput(ns("status")), br(),
          DT::dataTableOutput(ns("catalog_table")))
    ),
    fluidRow(
      box(title = cfg$rows_title, status = "info", solidHeader = TRUE, width = 12,
          fluidRow(
            column(4, textInput(ns(cfg$filter_input), sprintf("Filter by %s (optional):", cfg$id_noun))),
            column(4, numericInput(ns("max_rows"), "Max Rows to Display:", value = 500, min = 10, max = 5000, step = 10)),
            column(4, downloadButton(ns("download_components"), cfg$rows_download, class = "btn-info", style = "margin-top: 25px;"))
          ),
          DT::dataTableOutput(ns("component_table")))
    )
  )
}

catalog_browse_server <- function(id, api_manager, cfg) {
  moduleServer(id, function(input, output, session) {
    catalog_data <- reactiveVal(NULL)
    component_data <- reactiveVal(NULL)
    show_table <- function(d) DT::renderDataTable(DT::datatable(d, options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE))

    load_data <- function() {
      if (!bq_required(api_manager)) return()
      output$status <- renderUI(status_box("busy", " Loading data..."))
      tryCatch({
        api_manager[[cfg$cache]] <- NULL   # force a fresh pull, not the cached copy
        catalog <- api_manager[[cfg$taxonomy]]()
        catalog_data(catalog)
        output$catalog_table <- show_table(catalog)

        wanted <- trimws(input[[cfg$filter_input]] %||% "")
        limit <- safe_limit(input$max_rows, 500L)
        query <- if (nzchar(wanted)) {
          sprintf("SELECT * FROM `%s` WHERE %s = '%s' ORDER BY %s LIMIT %d", api_manager[[cfg$table]], cfg$id_col, safe_sql_escape(wanted), cfg$order_by, limit)
        } else sprintf("SELECT * FROM `%s` ORDER BY created_at DESC LIMIT %d", api_manager[[cfg$table]], limit)
        components <- api_manager$bq_query(query)
        component_data(components)
        output$component_table <- show_table(components)

        output$status <- renderUI(status_box("success", sprintf(cfg$loaded, nrow(catalog), nrow(components))))
      }, error = function(e) {
        output$status <- renderUI(status_box("error", " Error: ", app_err_text(e)))
        showNotification(paste("Error:", app_err_text(e)), type = "error")
      })
    }

    observeEvent(input$refresh, load_data())
    observeEvent(input[[cfg$filter_input]], load_data(), ignoreInit = TRUE)

    output$download_catalog <- csv_download(cfg$file_catalog, catalog_data)
    output$download_components <- csv_download(cfg$file_rows, component_data)
    output$status <- renderUI(tags$div())
    output$catalog_table <- DT::renderDataTable({})
    output$component_table <- DT::renderDataTable({})
  })
}

# ---- component_import: paste text, parse, preview, upload -------------------------------------------
# cfg (ui): title, intro, format_help (list of tags$li), placeholder
# cfg (server): pending (api_manager reactive holding text sent by the Generate tab), parse (text -> data frame),
#               new_id (topic -> id), insert (api_manager method), parsed_info (sprintf pattern: n, title, type, group, category, domain, topic)
component_import_ui <- function(id, cfg) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = cfg$title, status = "primary", solidHeader = TRUE, width = 12,
          cfg$intro,
          div(class = "alert alert-info", tags$strong("Expected Format:"), do.call(tags$ul, cfg$format_help)),
          textAreaInput(ns("diagram_text"), NULL, height = "450px", placeholder = cfg$placeholder),
          fluidRow(
            column(4, actionButton(ns("parse"), "Parse Components", class = "btn-info btn-lg", icon = icon("cogs"), width = "100%")),
            column(4, actionButton(ns("upload"), "Upload to BigQuery", class = "btn-success btn-lg", icon = icon("cloud-upload-alt"), width = "100%")),
            column(4, actionButton(ns("clear"), "Clear All", class = "btn-danger", icon = icon("trash"), width = "100%"))
          ),
          br(),
          htmlOutput(ns("status")),
          htmlOutput(ns("parse_info")))
    ),
    fluidRow(
      box(title = "Parsed Data Preview", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE,
          DT::dataTableOutput(ns("preview_table")))
    )
  )
}

component_import_server <- function(id, api_manager, cfg) {
  moduleServer(id, function(input, output, session) {
    parsed_data <- reactiveVal(NULL)

    # text pushed by the Generate tab's "Copy to Bulk Import" button
    observeEvent(api_manager[[cfg$pending]](), {
      incoming <- api_manager[[cfg$pending]]()
      if (nchar(incoming) > 0) updateTextAreaInput(session, "diagram_text", value = incoming)
    }, ignoreInit = FALSE)   # FALSE: a tab built lazily (after the hand-off) still picks the text up

    observeEvent(input$parse, {
      if (trimws(input$diagram_text %||% "") == "") {
        output$status <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"), " Please paste a generated diagram to parse"))
        return()
      }
      output$status <- renderUI(status_box("busy", " Parsing..."))
      tryCatch({
        # type, group, category, domain, topic and title come from the pasted text's own first lines; the id is made here from the topic
        df <- cfg$parse(input$diagram_text)
        df$diagram_id <- cfg$new_id(df$topic[1])
        parsed_data(df)

        output$parse_info <- renderUI(status_box("success", sprintf(cfg$parsed_info, nrow(df), df$title[1], df$diagram_type[1], df$diagram_group[1],
                                                                     df$category[1], df$domain[1], df$topic[1])))
        output$preview_table <- DT::renderDataTable(DT::datatable(
          df[, c("component_type", "layout_role", "grid_row", "grid_col", "sequence_order", "label_text", "items_packed")],
          options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE))
        output$status <- renderUI(status_box("success", sprintf(" Parsed %d component row(s)!", nrow(df))))
        showNotification(sprintf("✓ Parsed %d component row(s)!", nrow(df)), type = "message")
      }, error = function(e) {
        parsed_data(NULL)
        output$parse_info <- renderUI(status_box("error", " Parse issue: ", app_err_text(e)))
        output$preview_table <- DT::renderDataTable({})
        output$status <- renderUI(status_box("error", " Error: ", app_err_text(e)))
      })
    })

    observeEvent(input$upload, {
      if (!bq_required(api_manager)) return()
      df <- parsed_data()
      if (is.null(df) || nrow(df) == 0) { showNotification("Nothing parsed yet - click Parse Components first.", type = "warning"); return() }
      output$status <- renderUI(status_box("busy", " Uploading..."))
      tryCatch({
        rows_uploaded <- api_manager[[cfg$insert]](df)
        output$status <- renderUI(status_box("success", sprintf(" Uploaded %d component row(s)! Diagram ID: %s", rows_uploaded, df$diagram_id[1])))
        showNotification(sprintf("✓ Uploaded %d component row(s)!", rows_uploaded), type = "message")
      }, error = function(e) {
        output$status <- renderUI(status_box("error", " Error: ", app_err_text(e)))
        showNotification(paste("Error:", app_err_text(e)), type = "error")
      })
    })

    observeEvent(input$clear, {
      updateTextAreaInput(session, "diagram_text", value = "")
      parsed_data(NULL)
      output$parse_info <- renderUI(tags$div())
      output$preview_table <- DT::renderDataTable({})
      output$status <- renderUI(tags$div(class = "status-info", "Cleared."))
    })

    output$status <- renderUI(tags$div())
    output$parse_info <- renderUI(tags$div())
    output$preview_table <- DT::renderDataTable({})
  })
}

# ---- tool_recommender: the Editing Tool ranks the tools that fit a problem ----------------------------
# cfg (ui): title, how (text after "How this works:"), problem_label, placeholder, slider_label, spinner_text, results_title
# cfg (server): tag (log prefix), noun ("framework" | "tool"), types (valid ids), labels (id -> label), prompt (problem, n -> prompt),
#               parse (response, n -> data frame), set_pending (api_manager method), target_tab, target_label
tool_recommender_ui <- function(id, cfg) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = cfg$title, status = "primary", solidHeader = TRUE, width = 12,
          div(class = "alert alert-info", tags$strong("How this works:"), cfg$how),
          textAreaInput(ns("problem_description"), cfg$problem_label, height = "140px", placeholder = cfg$placeholder),
          sliderInput(ns("num_recommendations"), cfg$slider_label, min = 1, max = 8, value = 3, step = 1, width = "100%"),
          actionButton(ns("recommend"), "Get Recommendations", icon = icon("magic"), class = "btn-primary btn-lg", style = "width: 100%;"),
          br(), br(),
          div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
              icon("spinner", class = "fa-spin fa-3x"), h4(cfg$spinner_text)),
          htmlOutput(ns("status")))
    ),
    fluidRow(
      box(title = cfg$results_title, status = "success", solidHeader = TRUE, width = 12, collapsible = TRUE,
          DT::dataTableOutput(ns("recommendations_table")))
    )
  )
}

tool_recommender_server <- function(id, api_manager, cfg) {
  moduleServer(id, function(input, output, session) {
    recommendations <- reactiveVal(NULL)

    observeEvent(input$recommend, {
      if (!api_manager$claude_authenticated) {
        showNotification("Please configure and save Editing Tool API credentials first!", type = "error", duration = 10)
        return()
      }
      if (nchar(trimws(input$problem_description %||% "")) < 15) {
        showNotification("Please describe the problem in a bit more detail.", type = "error")
        return()
      }

      shinyjs::show("loading_spinner")
      output$status <- renderUI(status_box("busy", " Analysing (this may take 20-40 seconds)..."))
      recommendations(NULL)
      output$recommendations_table <- DT::renderDataTable({})

      n <- input$num_recommendations
      prompt <- cfg$prompt(input$problem_description, n)

      cat("========================================================\n")
      cat(sprintf("\U0001F9E0 [%s][DEBUG] Requesting %s recommendations from the Editing Tool\n", cfg$tag, cfg$noun))
      cat(sprintf("    num_recommendations : %d\n", n))
      cat(sprintf("    problem_description  : %s\n", input$problem_description))
      cat(sprintf("    catalog_size          : %d %ss offered\n", length(cfg$types), cfg$noun))
      cat(sprintf("    prompt_length         : %d characters\n", nchar(prompt)))
      cat("========================================================\n")

      tryCatch({
        t0 <- Sys.time()
        response_text <- api_manager$call_claude(prompt = prompt)
        elapsed <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)

        df <- cfg$parse(response_text, n)
        recommendations(df)
        cat(sprintf("\U0001F9E0 [%s][DEBUG] Got %d valid recommendation(s) in %ss: %s\n", cfg$tag, nrow(df), elapsed, paste(df$diagram_type, collapse = ", ")))
        shinyjs::hide("loading_spinner")

        rank_badge <- function(r) sprintf('<div class="recommender-rank-badge">%d</div>', r)
        tool_link <- function(dtype, label) sprintf(
          '<a href="#" class="recommender-tool-link" onclick="Shiny.setInputValue(\'%s\', \'%s\', {priority: \'event\'}); return false;">%s</a>',
          session$ns("tool_clicked"), dtype, htmltools::htmlEscape(label))
        display_df <- data.frame(
          Rank = sapply(df$rank, rank_badge),
          Tool = mapply(tool_link, df$diagram_type, df$diagram_label),
          Group = df$diagram_group_label,
          Reasoning = htmltools::htmlEscape(df$reasoning),
          Drawbacks = htmltools::htmlEscape(df$drawbacks),
          stringsAsFactors = FALSE)

        output$recommendations_table <- DT::renderDataTable(DT::datatable(
          display_df, escape = FALSE, rownames = FALSE, selection = "none", class = "display recommender-table",
          options = list(pageLength = 10, dom = "t", ordering = FALSE,
                         columnDefs = list(list(width = "60px", targets = 0, className = "dt-center"),
                                           list(width = "180px", targets = 1), list(width = "110px", targets = 2)))))

        output$status <- renderUI(if (nrow(df) < n)
          status_box("warning", sprintf(" Got %d valid recommendation(s) out of the %d requested (one or more had an unrecognized tool id and was dropped - see console).", nrow(df), n))
        else status_box("success", sprintf(" %d recommendation(s) ready. Click any tool name to generate it.", nrow(df))))
      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        cat(sprintf("❌ [%s][DEBUG] Failed: %s\n", cfg$tag, app_err_text(e)))
        output$status <- renderUI(status_box("error", " Error: ", app_err_text(e)))
        showNotification(paste("Error:", app_err_text(e)), type = "error", duration = 15)
      })
    })

    # A recommended tool was clicked: remember its id and open the Generate tab, which selects it in its dropdowns.
    observeEvent(input$tool_clicked, {
      dtype <- input$tool_clicked
      if (is.null(dtype) || !dtype %in% cfg$types) return()
      cat(sprintf("\U0001F5B1️  [%s][DEBUG] Recommended tool clicked: %s -> jumping to %s\n", cfg$tag, dtype, cfg$target_label))
      api_manager[[cfg$set_pending]](dtype)
      td_nav(session, cfg$target_tab)
      showNotification(sprintf("✓ %s selected - jumping to %s", cfg$labels[[dtype]], cfg$target_label), type = "message")
    })

    output$status <- renderUI(tags$div())
    output$recommendations_table <- DT::renderDataTable({})
  })
}
