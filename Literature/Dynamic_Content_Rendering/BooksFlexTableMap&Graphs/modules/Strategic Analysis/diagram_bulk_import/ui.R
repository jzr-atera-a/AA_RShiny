# modules/Strategic Analysis/diagram_bulk_import/ui.R

diagram_bulk_import_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Bulk Import Diagram Components to BigQuery",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        p("Paste text produced by the Generate Diagram tab (or written by hand in the same format). ",
          "Parse it first to preview the components, then upload. Diagram type, category, domain, topic, and ",
          "title are read directly from the pasted text's metadata lines - no need to re-select them here."),

        div(class = "alert alert-info",
            tags$strong("Expected Format:"),
            tags$ul(
              tags$li("First 5 lines (metadata, no field names): [diagram_type]", tags$br(),
                      "[category]", tags$br(), "[domain]", tags$br(), "[topic]", tags$br(), "[title]"),
              tags$li("Then one blank line, then one block per component:"),
              tags$li("[component_type]: shape_rectangle"),
              tags$li("[layout_role]: grid_cell"),
              tags$li("[grid_row]: 1 [grid_col]: 1 [sequence_order]: 1"),
              tags$li("[label_text]: ...  [sub_text]: ...  [items_packed]: item1", HTML("&nbsp;|||DIAGITEM|||&nbsp;"), "item2")
            )
        ),

        textAreaInput(ns("diagram_text"), NULL, height = "450px",
                      placeholder = "[grid]\n[Business]\n[Situational Analysis]\n[Trading Hedge Fund Startup]\n[Trading Hedge Fund Analysis]\n\n[component_type]: shape_rectangle\n[layout_role]: grid_cell\n[grid_row]: 1\n[grid_col]: 1\n..."),

        fluidRow(
          column(4, actionButton(ns("parse"), "Parse Components", class = "btn-info btn-lg", icon = icon("cogs"), width = "100%")),
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
