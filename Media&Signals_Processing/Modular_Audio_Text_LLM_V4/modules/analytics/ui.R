analytics_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      valueBoxOutput(ns("totalFiles")),
      valueBoxOutput(ns("totalWords")),
      valueBoxOutput(ns("avgTime"))
    ),
    
    fluidRow(
      box(
        title = "Word Count Distribution",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        plotlyOutput(ns("wordPlot"))
      ),
      
      box(
        title = "Processing Time",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        plotlyOutput(ns("timePlot"))
      )
    ),
    
    fluidRow(
      box(
        title = "Transcription History",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        DTOutput(ns("historyTable"))
      )
    )
  )
}