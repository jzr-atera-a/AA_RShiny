summary_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Step 1: Load Transcription",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        
        fileInput(ns("transcriptFile"), "Choose .txt file:", accept = ".txt"),
        verbatimTextOutput(ns("fileInfo")),
        br(),
        actionButton(ns("loadBtn"), "Load Transcription", class = "btn-info", style = "width: 100%;"),
        br(), br(),
        verbatimTextOutput(ns("loadedInfo"))
      ),
      
      box(
        title = "Step 2: Configure Summary",
        status = "warning",
        solidHeader = TRUE,
        width = 6,
        
        textAreaInput(ns("instructions"), "Instructions:",
                      value = "Please provide a comprehensive summary of this conversation covering:\n1. Main topics discussed\n2. Key points and decisions made\n3. Action items or next steps\n4. Important questions or concerns raised",
                      height = "200px"),
        
        checkboxInput(ns("useTimeout"), "Enable timeout", value = FALSE),
        conditionalPanel(
          condition = sprintf("input[\'%s\']", ns("useTimeout")),
          numericInput(ns("timeout"), "Timeout (seconds):", value = 180, min = 30, max = 600)
        ),
        br(),
        actionButton(ns("generateBtn"), "Generate Summary", class = "btn-success btn-lg", style = "width: 100%;")
      )
    ),
    
    fluidRow(
      box(
        title = "Generation Status",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        verbatimTextOutput(ns("status"))
      )
    ),
    
    fluidRow(
      box(
        title = "Generated Summary",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        
        textAreaInput(ns("summary"), NULL, height = "500px", placeholder = "Summary will appear here..."),
        
        fluidRow(
          column(8, textInput(ns("savePath"), "Save directory:", placeholder = "Select directory...")),
          column(2, br(), shinyDirButton(ns("browseDir"), "Browse...", "Select Directory")),
          column(2, br(), actionButton(ns("saveBtn"), "Save", class = "btn-success", style = "width: 100%;"))
        )
      )
    )
  )
}