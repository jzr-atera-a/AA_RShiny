# modules/Funding Programmes/funding_browse/ui.R

funding_browse_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Browse Planned Programmes", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(2, actionButton(ns("refresh"), "Refresh Data", class = "btn-primary", icon = icon("sync"))),
            column(2, downloadButton(ns("download"), "Download CSV", class = "btn-info")),
            column(2, downloadButton(ns("download_calendar"), "📅 Calendar", class = "btn-success")),
            column(6, numericInput(ns("max_rows"), "Max Rows to Display:", value = 200, min = 10, max = 2000, step = 10))
          ),
          br(), htmlOutput(ns("status")), br(),
          DT::dataTableOutput(ns("table"))
      )
    )
  )
}
