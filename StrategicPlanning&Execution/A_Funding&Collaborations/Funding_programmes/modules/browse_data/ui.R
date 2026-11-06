# modules/browse_data/ui.R

browse_data_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Browse All Planned Schedules",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        fluidRow(
          column(3, actionButton(ns("refresh"), "Refresh Data", class = "btn-primary",
                                 icon = icon("sync"))),
          column(3, downloadButton(ns("download"), "Download CSV", class = "btn-info")),
          column(6, numericInput(ns("max_rows"), "Max Rows to Display:", 
                                 value = 200, min = 10, max = 2000, step = 10))
        ),
        
        br(),
        htmlOutput(ns("status")),
        br(),
        DT::dataTableOutput(ns("table"))
      )
    )
  )
}
