# modules/bulk_import/ui.R

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
