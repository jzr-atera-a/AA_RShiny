# modules/browse_data/ui.R

browse_data_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Browse All Stored Rows (raw append-only backup)",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        p("This shows every versioned row exactly as stored, including full edit history - ",
          "each edit is a NEW row (change_type = 'create'/'update'/'delete'), never an overwrite. ",
          "For the current, deduplicated state of a specific graph, use one of the Visualize tabs or Edit Graph instead."),

        fluidRow(
          column(3, actionButton(ns("refresh"), "Refresh Data", class = "btn-primary", icon = icon("sync"))),
          column(3, downloadButton(ns("download"), "Download CSV", class = "btn-info")),
          column(6, numericInput(ns("max_rows"), "Max Rows to Display:", value = 200, min = 10, max = 5000, step = 10))
        ),

        br(),
        htmlOutput(ns("status")),
        br(),
        DT::dataTableOutput(ns("table"))
      )
    )
  )
}
