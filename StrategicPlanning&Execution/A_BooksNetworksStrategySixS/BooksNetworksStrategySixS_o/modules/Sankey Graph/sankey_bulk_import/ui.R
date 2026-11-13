# modules/Sankey Graph/sankey_bulk_import/ui.R

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
