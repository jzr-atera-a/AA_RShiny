converter_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Audio File Upload", 
        status = "primary", 
        solidHeader = TRUE,
        width = 6,
        
        fileInput(ns("audioFile"), "Choose Audio File (M4A or MP3)", accept = c(".m4a", ".mp3")),
        verbatimTextOutput(ns("fileInfo")),
        
        h5("Output Settings:"),
        fluidRow(
          column(8, textInput(ns("outputPath"), "Save to directory:", placeholder = "Select directory...")),
          column(4, br(), shinyDirButton(ns("browseDir"), "Browse...", "Select Directory"))
        ),
        textInput(ns("outputPrefix"), "Output file prefix:", placeholder = "Leave empty for original name")
      ),
      
      box(
        title = "Split Settings", 
        status = "info", 
        solidHeader = TRUE,
        width = 6,
        
        radioButtons(ns("splitMethod"), "Split Method:",
                     choices = list("By Number of Files" = "num_files", "By File Size" = "file_size"),
                     selected = "file_size"),
        
        conditionalPanel(
          condition = sprintf("input['%s'] == 'num_files'", ns("splitMethod")),
          numericInput(ns("numSplits"), "Number of MP3 files:", value = 2, min = 1, max = 50)
        ),
        
        conditionalPanel(
          condition = sprintf("input['%s'] == 'file_size'", ns("splitMethod")),
          numericInput(ns("maxSizeMB"), "Maximum file size (MB):", value = 10, min = 1, max = 500)
        ),
        
        br(),
        actionButton(ns("processBtn"), "Convert & Split Audio", class = "btn-success btn-lg", style = "width: 100%;")
      )
    ),
    
    fluidRow(
      box(
        title = "Processing Status", 
        status = "warning", 
        solidHeader = TRUE,
        width = 12,
        verbatimTextOutput(ns("status"))
      )
    ),
    
    fluidRow(
      box(
        title = "Results", 
        status = "success", 
        solidHeader = TRUE,
        width = 12,
        DTOutput(ns("resultsTable"))
      )
    )
  )
}
