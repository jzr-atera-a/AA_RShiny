transcription_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Audio Upload",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        
        fileInput(ns("audioFiles"), "Choose Audio Files (up to 10)", multiple = TRUE, accept = c(".mp3", ".m4a", ".flac", ".ogg")),
        verbatimTextOutput(ns("fileInfo")),
        
        h5("Settings:"),
        checkboxInput(ns("useTimeout"), "Enable timeout", value = FALSE),
        conditionalPanel(
          condition = sprintf("input[\'%s\']", ns("useTimeout")),
          numericInput(ns("timeout"), "Timeout (seconds):", value = 180, min = 30, max = 600)
        ),
        br(),
        actionButton(ns("transcribeBtn"), "Transcribe", class = "btn-primary btn-lg", style = "width: 100%;")
      ),
      
      box(
        title = "Processing Status",
        status = "info",
        solidHeader = TRUE,
        width = 6,
        verbatimTextOutput(ns("status"))
      )
    ),
    
    fluidRow(
      box(
        title = "Transcription Results",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        
        textAreaInput(ns("results"), NULL, height = "500px", placeholder = "Results will appear here..."),
        
        fluidRow(
          column(8, textInput(ns("savePath"), "Save directory:", placeholder = "Select directory...")),
          column(2, br(), shinyDirButton(ns("browseDir"), "Browse...", "Select Directory")),
          column(2, br(), actionButton(ns("saveBtn"), "Save", class = "btn-success", style = "width: 100%;"))
        )
      )
    )
  )
}