# modules/generate_table/ui.R

generate_table_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Table Definition",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        p("Define what the ROWS and COLUMNS of your comparison table represent. ",
          "Claude decides how many columns are actually relevant - the number can be ",
          "different every time you generate a table, and that's fine: it's stored as ",
          "flexible delimited text, not fixed BigQuery columns."),

        fluidRow(
          column(6,
                 category_topic_dropdown_ui(ns)
          ),
          column(6,
                 textInput(ns("table_title"), "Table Title:",
                           placeholder = "e.g., ML Models for Forecasting Asset Class Prices"),
                 textInput(ns("row_dimension_label"), "What do the ROWS represent? *",
                           placeholder = "e.g., Financial Asset Class"),
                 textInput(ns("column_dimension_label"), "What do the COLUMNS represent? *",
                           placeholder = "e.g., Machine Learning Model")
          )
        ),

        textAreaInput(ns("request_description"), "Describe what you want compared: *",
                      rows = 5, width = "100%",
                      placeholder = paste0(
                        "e.g., For each major financial asset class, contrast the strengths and ",
                        "weaknesses of the different machine learning models commonly used to ",
                        "forecast their prices. Include model name, typical accuracy trade-offs, ",
                        "data requirements, and when it is the wrong tool for that asset class.")),

        hr(),

        fluidRow(
          column(3,
                 actionButton(ns("generate"), "Generate Table", icon = icon("magic"),
                              class = "btn-primary btn-lg", style = "width: 100%;")
          ),
          column(3,
                 actionButton(ns("copy_to_bulk"), "Copy to Bulk Import", icon = icon("arrow-right"),
                              class = "btn-info btn-lg", style = "width: 100%;")
          ),
          column(3,
                 actionButton(ns("parse_and_upload"), "Parse & Upload Direct", icon = icon("cloud-upload-alt"),
                              class = "btn-success btn-lg", style = "width: 100%;")
          ),
          column(3,
                 downloadButton(ns("download"), "Download Text", class = "btn-warning", style = "width: 100%;")
          )
        )
      )
    ),

    fluidRow(
      box(
        title = "Generated Table (raw delimited text)",
        status = "success",
        solidHeader = TRUE,
        width = 12,

        div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
            icon("spinner", class = "fa-spin fa-3x"),
            h4("Generating table... This may take a minute or two for wide tables.")),

        verbatimTextOutput(ns("generated_table_text")),
        htmlOutput(ns("status"))
      )
    ),

    fluidRow(
      box(
        title = "Preview",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        p("A quick preview of the parsed rows/columns before you upload. Load it via 'Parse & Upload Direct' above, ",
          "or check the Table Viewer tab after uploading for the full scrollable, LaTeX-rendered grid."),
        htmlOutput(ns("preview_html"))
      )
    )
  )
}
