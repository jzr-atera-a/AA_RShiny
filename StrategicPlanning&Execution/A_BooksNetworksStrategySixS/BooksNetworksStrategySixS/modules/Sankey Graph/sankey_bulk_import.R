# modules/Sankey Graph/sankey_bulk_import.R
# ---- module --------------------------------------------------------------------------------------
# id:           sankey_bulk_import
# name:         Sankey Bulk Import
# label:        Bulk Import
# icon:         file-import
# description:  Paste or receive-from-Generate Sankey node/link text, parse, preview, upload
# packages:     shiny, shinydashboard, DT
# api_optional: bigquery
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

sankey_bulk_import_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Bulk Import Sankey Node/Link Rows to BigQuery",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        p("Paste text produced by the Generate Sankey tab (or written by hand in the same format). ",
          "Parse it first to preview the nodes/links, then upload. Column count, row count, category, ",
          "domain, topic, and title are all read directly from the pasted text's metadata lines - no need ",
          "to re-select them here."),

        div(class = "alert alert-info",
            tags$strong("Expected Format:"),
            tags$ul(
              tags$li("First 6 lines (metadata, no field names): [number of columns]", tags$br(),
                      "[number of initial rows]", tags$br(), "[category]", tags$br(),
                      "[domain]", tags$br(), "[topic]", tags$br(), "[title]"),
              tags$li("Then one blank line, then one block per node or link:"),
              tags$li("[row_kind]: node  (or link)"),
              tags$li("Node: [component_ref] [column_index] [sequence_order] [label_text] [sub_text] [items_packed] [color_hint]"),
              tags$li("Link: [source_ref] [target_ref] [value_numeric] [unit_label]"),
              tags$li("A link's target column must always be strictly later than its source column - skip-ahead links (bypassing intermediate columns) are fine.")
            )
        ),

        textAreaInput(ns("sankey_text"), NULL, height = "450px",
                      placeholder = "[6]\n[8]\n[Business]\n[Energy]\n[UK Power Grid]\n[UK Electricity Flow 2026]\n\n[row_kind]: node\n[component_ref]: c1n1\n[column_index]: 1\n..."),

        fluidRow(
          column(4, actionButton(ns("parse"), "Parse Rows", class = "btn-info btn-lg", icon = icon("cogs"), width = "100%")),
          column(4, actionButton(ns("upload"), "Upload to BigQuery", class = "btn-success btn-lg", icon = icon("cloud-upload-alt"), width = "100%")),
          column(4, actionButton(ns("clear"), "Clear All", class = "btn-danger", icon = icon("trash"), width = "100%"))
        ),

        br(),
        htmlOutput(ns("status")),
        htmlOutput(ns("parse_info"))
      )
    ),

    fluidRow(
      box(title = "Parsed Data Preview", status = "info", solidHeader = TRUE, width = 12,
          collapsible = TRUE,
          DT::dataTableOutput(ns("preview_table")))
    )
  )
}

# ==== Server =======================================================================================

sankey_bulk_import_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed_data <- reactiveVal(NULL)

    observeEvent(api_manager$pending_bulk_text_sankey(), {
      incoming_text <- api_manager$pending_bulk_text_sankey()
      if (nchar(incoming_text) > 0) {
        updateTextAreaInput(session, "sankey_text", value = incoming_text)
      }
    }, ignoreInit = FALSE)   # FALSE: a tab built lazily (after the hand-off) still picks the text up

    observeEvent(input$parse, {
      if (trimws(input$sankey_text %||% "") == "") {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                   " Please paste a generated Sankey to parse")
        })
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing...")
      })

      tryCatch({
        df <- parse_sankey_text(input$sankey_text, sankey_id = "", is_template = FALSE, created_by = "manual_bulk_import")
        df$sankey_id <- generate_new_sankey_id(df$topic[1])

        parsed_data(df)

        node_count <- sum(df$row_kind == "node")
        link_count <- sum(df$row_kind == "link")

        output$parse_info <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully parsed %d node(s) and %d link(s) for '%s' (%d columns | Category: %s | Domain: %s | Topic: %s)",
                           node_count, link_count, df$title[1], df$num_columns[1], df$category[1], df$domain[1], df$topic[1]))
        })

        output$preview_table <- DT::renderDataTable({
          DT::datatable(df[, c("row_kind", "component_ref", "column_index", "sequence_order",
                                "label_text", "source_ref", "target_ref", "value_numeric", "unit_label")],
                       options = list(pageLength = 12, scrollX = TRUE), rownames = FALSE)
        })

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Parsed %d node(s) and %d link(s)!", node_count, link_count))
        })

        showNotification(sprintf("✓ Parsed %d node(s) and %d link(s)!", node_count, link_count), type = "message")

      }, error = function(e) {
        parsed_data(NULL)
        output$parse_info <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Parse issue: ", app_err_text(e))
        })
        output$preview_table <- DT::renderDataTable({})
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", app_err_text(e))
        })
      })
    })

    observeEvent(input$upload, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      df <- parsed_data()
      if (is.null(df) || nrow(df) == 0) { showNotification("Nothing parsed yet - click Parse Rows first.", type = "warning"); return() }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Uploading...")
      })

      tryCatch({
        rows_uploaded <- api_manager$bq_insert_sankey(df)
        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Uploaded %d row(s)! Sankey ID: %s", rows_uploaded, df$sankey_id[1]))
        })
        showNotification(sprintf("✓ Uploaded %d row(s)!", rows_uploaded), type = "message")
      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", app_err_text(e))
        })
        showNotification(paste("Error:", app_err_text(e)), type = "error")
      })
    })

    observeEvent(input$clear, {
      updateTextAreaInput(session, "sankey_text", value = "")
      parsed_data(NULL)
      output$parse_info <- renderUI({ tags$div() })
      output$preview_table <- DT::renderDataTable({})
      output$status <- renderUI({ tags$div(class = "status-info", "Cleared.") })
    })

    output$status <- renderUI({ tags$div() })
    output$parse_info <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({})
  })
}
