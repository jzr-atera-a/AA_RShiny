# modules/browse_data/ui.R

browse_data_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Browse All Book Summaries",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        fluidRow(
          column(3, actionButton(ns("refresh"), "Refresh Data", class = "btn-primary",
                                 icon = icon("sync"))),
          column(3, downloadButton(ns("download"), "Download CSV", class = "btn-info")),
          column(6, numericInput(ns("max_rows"), "Max Rows to Display:", 
                                 value = 100, min = 10, max = 1000, step = 10))
        ),
        
        br(),
        htmlOutput(ns("status")),
        br(),
        DT::dataTableOutput(ns("table"))
      )
    )
  )
}
