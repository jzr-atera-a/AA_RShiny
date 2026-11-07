# modules/browse_data/ui.R

browse_data_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Browse All Stored Rows (raw backup view)",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        p("This shows the raw BigQuery rows, including the delimited ", tags$code("columns_data"),
          " text column, exactly as stored - useful as a personal backup export. ",
          "For a human-readable rendered table, use the Table Viewer tab."),

        fluidRow(
          column(3, actionButton(ns("refresh"), "Refresh Data", class = "btn-primary",
                                 icon = icon("sync"))),
          column(3, downloadButton(ns("download"), "Download CSV", class = "btn-info")),
          column(6, numericInput(ns("max_rows"), "Max Rows to Display:",
                                 value = 200, min = 10, max = 5000, step = 10))
        ),

        br(),
        htmlOutput(ns("status")),
        br(),
        DT::dataTableOutput(ns("table"))
      )
    )
  )
}
