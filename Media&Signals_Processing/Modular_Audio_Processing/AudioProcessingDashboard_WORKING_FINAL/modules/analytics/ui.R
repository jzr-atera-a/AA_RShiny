analytics_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      # Summary Statistics
      valueBoxOutput(ns("totalFiles"), width = 4),
      valueBoxOutput(ns("totalWords"), width = 4),
      valueBoxOutput(ns("avgDuration"), width = 4)
    ),
    
    fluidRow(
      # Word Count Analysis
      box(
        title = "Word Count Distribution",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        withSpinner(plotlyOutput(ns("wordCountPlot")))
      ),
      
      # Processing Time Analysis
      box(
        title = "Processing Time Trends",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        withSpinner(plotlyOutput(ns("processingTimePlot")))
      )
    ),
    
    fluidRow(
      # Transcription History
      box(
        title = "Transcription History",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        withSpinner(DT::dataTableOutput(ns("historyTable")))
      )
    )
  )
}
