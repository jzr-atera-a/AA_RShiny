# modules/Flex Table/bulk_import.R
# ---- module --------------------------------------------------------------------------------------
# id:           bulk_import
# name:         Bulk Import
# icon:         file-import
# description:  Parse and upload a raw generated table (paste text)
# packages:     shiny, shinydashboard, DT
# api_required: bigquery
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

bulk_import_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Paste Generated Table Text",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        p("Paste text produced by the Generate Table tab (or written by hand in the same format). ",
          "Parse it first to preview the rows/columns, then upload."),

        textAreaInput(ns("summary_upload_text"), NULL, rows = 15, width = "100%",
                      placeholder = "[Category]\n[Topic]\n[Table Title]\n[Row Dimension Label]\n[Column Dimension Label]\n\n[row_index]: ...\n[columns_data]: Header1|||KV|||Value1|||COL|||Header2|||KV|||Value2\n[notes]: ..."),

        fluidRow(
          column(4, actionButton(ns("parse"), "Parse Text", class = "btn-primary btn-lg",
                                 icon = icon("cogs"), style = "width: 100%;")),
          column(4, actionButton(ns("upload"), "Upload to BigQuery", class = "btn-success btn-lg",
                                 icon = icon("cloud-upload-alt"), style = "width: 100%;")),
          column(4, actionButton(ns("clear"), "Clear", class = "btn-danger btn-lg",
                                 icon = icon("trash"), style = "width: 100%;"))
        ),

        br(),
        htmlOutput(ns("status")),
        htmlOutput(ns("parse_info"))
      )
    ),

    fluidRow(
      box(
        title = "Parsed Preview",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        DT::dataTableOutput(ns("preview_table"))
      )
    )
  )
}

# ==== Server =======================================================================================

bulk_import_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed_data <- reactiveVal(NULL)

    # Receive text pushed from the Generate Table tab's "Copy to Bulk
    # Import" button (see APIManager$pending_bulk_text_flex in R/utils_api.R)
    observeEvent(api_manager$pending_bulk_text_flex(), {
      incoming_text <- api_manager$pending_bulk_text_flex()
      if (nchar(incoming_text) > 0) {
        updateTextAreaInput(session, "summary_upload_text", value = incoming_text)
      }
    }, ignoreInit = FALSE)   # FALSE: a tab built lazily (after the hand-off) still picks the text up

    observeEvent(input$parse, {

      if (trimws(input$summary_upload_text) == "") {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please paste a generated table to parse")
        })
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Parsing...")
      })

      tryCatch({
        parsed_df <- parse_table_text(input$summary_upload_text)
        parsed_data(parsed_df)

        output$parse_info <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully parsed %d row(s) for '%s' (Category: %s | Topic: %s | Rows = %s | Columns = %s)",
                           nrow(parsed_df), parsed_df$table_title[1], parsed_df$category[1], parsed_df$topic[1],
                           parsed_df$row_dimension_label[1], parsed_df$column_dimension_label[1]))
        })

        output$preview_table <- DT::renderDataTable({
          DT::datatable(parsed_df, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
        })

        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Parsed %d row(s)!", nrow(parsed_df)))
        })

        showNotification(sprintf("✓ Parsed %d row(s)!", nrow(parsed_df)), type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Error: ", app_err_text(e))
        })
        showNotification(paste("Error:", app_err_text(e)), type = "error")
      })
    })

    observeEvent(input$upload, {

      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }

      if (is.null(parsed_data())) {
        showNotification("Please parse the table first!", type = "error")
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Uploading...")
      })

      tryCatch({
        rows_uploaded <- api_manager$bq_insert_flex(parsed_data(), source = "claude")

        api_manager$trigger_state_update_flex()

        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully uploaded %d rows! Table Viewer updated.", rows_uploaded))
        })

        showNotification(sprintf("✓ Uploaded %d rows!", rows_uploaded), type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Error: ", app_err_text(e))
        })
        showNotification(paste("Error:", app_err_text(e)), type = "error")
      })
    })

    observeEvent(input$clear, {
      updateTextAreaInput(session, "summary_upload_text", value = "")
      parsed_data(NULL)
      output$parse_info <- renderUI({})
      output$preview_table <- DT::renderDataTable({})
      output$status <- renderUI({
        tags$div(class = "status-info", "Cleared.")
      })
    })

    output$status <- renderUI({ tags$div() })
    output$parse_info <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({})

  })
}
