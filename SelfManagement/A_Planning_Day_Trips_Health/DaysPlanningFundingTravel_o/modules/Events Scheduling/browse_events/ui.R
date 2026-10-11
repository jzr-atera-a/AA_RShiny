# modules/browse_events/ui.R

browse_events_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Browse All Events", status = "primary", solidHeader = TRUE, width = 12,

        fluidRow(
          column(2, actionButton(ns("refresh"), "Refresh Data",   class = "btn-primary", icon = icon("sync"))),
          column(2, downloadButton(ns("download"), "Download CSV", class = "btn-info")),
          column(2, downloadButton(ns("download_calendar"), "📅 Calendar", class = "btn-success")),
          column(2, selectInput(ns("filter_city"),     "Filter by City:",     choices = c("All" = ""))),
          column(2, selectInput(ns("filter_category"), "Filter by Category:", choices = c("All" = "")))
        ),

        br(),
        fluidRow(
          column(6, numericInput(ns("max_rows"), "Max Rows:", value = 200, min = 10, max = 2000, step = 50)),
          column(6, htmlOutput(ns("status")))
        ),

        br(),
        DT::dataTableOutput(ns("table"))
      )
    )
  )
}
