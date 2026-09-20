# modules/econ_calendar_export.R
#
# "Parse & Export to BigQuery" — reviews the batch most recently generated on
# the Daily/Weekly Trend Summary tab (held on the shared api_manager) and
# commits it to BigQuery. Also supports pasting raw Claude output directly
# and re-parsing it here, for cases where you want to regenerate or edit the
# text before committing.

econ_calendar_export_ui <- function(id) {
  ns <- NS(id)
  tagList(
    ua_intro("Economic Calendars", "Parse & Export to BigQuery", "\u2014", "\u2014",
             "Review the most recently generated summary batch, then commit it to BigQuery as one row per event/asset combination."),

    fluidRow(
      box(title = "Current Batch", status = "primary", solidHeader = TRUE, width = 12,
          uiOutput(ns("batchInfo")),
          actionButton(ns("loadLast"), "Load Last Generated Batch", icon = icon("rotate")),
          tags$hr(),
          tags$p("Or paste/edit raw Claude output to re-parse manually:"),
          textAreaInput(ns("rawPaste"), NULL, rows = 6, placeholder = "EVENT|||... / ASSET|||... / ---END EVENT---"),
          dateInput(ns("pasteDate"), "Query date for this pasted batch:", value = Sys.Date()),
          actionButton(ns("reparse"), "Re-parse Pasted Text", icon = icon("code"))
      )
    ),

    fluidRow(
      box(title = "Rows Ready to Export", status = "success", solidHeader = TRUE, width = 12,
          withSpinner(DT::dataTableOutput(ns("exportTable"))),
          tags$hr(),
          actionButton(ns("exportBtn"), "Export to BigQuery", icon = icon("cloud-arrow-up"), class = "btn-success"),
          uiOutput(ns("exportStatus"))
      )
    )
  )
}

econ_calendar_export_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    current_batch <- reactiveVal(data.frame())

    render_batch <- function(df) {
      current_batch(df)
      output$exportTable <- DT::renderDataTable({
        DT::datatable(df, options = list(scrollX = TRUE, pageLength = 15), rownames = FALSE)
      })
    }

    observeEvent(input$loadLast, {
      df <- api_manager$last_parsed_df
      if (is.null(df) || nrow(df) == 0) {
        output$batchInfo <- renderUI(tags$div(style="color:#e67e22;", "No batch generated yet \u2014 go to Daily/Weekly Trend Summary first."))
        return()
      }
      output$batchInfo <- renderUI(tags$div(style="color:#27ae60;",
        icon("check-circle"), sprintf(" Loaded batch %s (query date %s) \u2014 %d row(s)",
                                       api_manager$last_query_id, api_manager$last_query_date, nrow(df))))
      render_batch(df)
    })

    observeEvent(input$reparse, {
      req(trimws(input$rawPaste) != "")
      parsed <- etc_parse_response(input$rawPaste, input$pasteDate)
      output$batchInfo <- renderUI(tags$div(style="color:#27ae60;",
        sprintf("Re-parsed pasted text \u2014 %d row(s)", nrow(parsed))))
      render_batch(parsed)
    })

    observeEvent(input$exportBtn, {
      df <- current_batch()
      if (nrow(df) == 0) {
        output$exportStatus <- renderUI(tags$div(style="color:#e67e22; margin-top:8px;", "Nothing loaded to export."))
        return()
      }
      if (!isTRUE(api_manager$bq_authenticated)) {
        output$exportStatus <- renderUI(tags$div(style="color:#c0392b; margin-top:8px;",
          "Configure BigQuery credentials on the API Configuration \u2192 BigQuery tab first."))
        return()
      }
      tryCatch({
        n <- api_manager$bq_insert_economic_calendar(df)
        output$exportStatus <- renderUI(tags$div(style="color:#27ae60; margin-top:8px;",
          icon("check-circle"), sprintf(" Exported %d row(s) to %s", n, api_manager$bq_full_table_economic_calendar)))
        showNotification(sprintf("\u2713 Exported %d row(s) to BigQuery", n), type = "message")
      }, error = function(e) {
        output$exportStatus <- renderUI(tags$div(style="color:#c0392b; margin-top:8px;", "Export failed: ", e$message))
      })
    })

    output$batchInfo <- renderUI(tags$div("No batch loaded."))
    output$exportStatus <- renderUI(tags$div())
    output$exportTable <- DT::renderDataTable(DT::datatable(data.frame(), options = list(dom = 't'), rownames = FALSE))
  })
}
