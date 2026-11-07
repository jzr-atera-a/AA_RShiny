# modules/table_viewer/ui.R

table_viewer_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Select Table to View",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        p("All four filters below are required to uniquely identify a table: a single Category + ",
          "Topic can contain several distinct subtables (e.g. Column Label 'Arms Top 3' vs 'Legs Top 7' ",
          "under the same Topic). Once all four are selected, the FULL grid loads - every row, every ",
          "column - using the Row/Column Dimension Labels as the axis headings."),

        fluidRow(
          column(3, selectInput(ns("viz_category"), "Category: *", choices = NULL)),
          column(3, selectInput(ns("viz_topic"), "Topic: *", choices = NULL)),
          column(3, selectInput(ns("row_label_select"), "Rows Label (row_dimension_label): *", choices = NULL)),
          column(3, selectInput(ns("column_label_select"), "Columns Label (column_dimension_label): *", choices = NULL))
        ),

        fluidRow(
          column(12, actionButton(ns("load_table"), "Load Table",
                                 class = "btn-success btn-lg", icon = icon("th"),
                                 style = "width: 100%;"))
        ),

        hr(),
        htmlOutput(ns("status"))
      )
    ),

    fluidRow(
      box(
        title = "Table Overview",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        htmlOutput(ns("table_header")),
        fluidRow(
          column(3, valueBoxOutput(ns("total_rows"), width = 12)),
          column(3, valueBoxOutput(ns("total_columns"), width = 12)),
          column(3, valueBoxOutput(ns("row_dim"), width = 12)),
          column(3, valueBoxOutput(ns("col_dim"), width = 12))
        )
      )
    ),

    fluidRow(
      box(
        title = "Comparison Table (scroll left-right and up-down)",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,

        downloadButton(ns("download_wide_csv"), "Download as Wide CSV", class = "btn-warning"),
        br(), br(),

        sliderInput(ns("column_width_chars"), "Column Width (characters):",
                    min = 30, max = 110, value = 70, step = 20, width = "100%"),
        p(style = "color: #7f8c8d; font-size: 12px; margin-top: -10px;",
          "Adjusts how wide each data column is before text wraps to the next line. ",
          "Words are never cut mid-word - if a word doesn't fit, it moves to the next line."),
        br(),

        uiOutput(ns("comparison_table_html"))
      )
    )
  )
}
