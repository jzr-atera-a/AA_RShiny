bulk_analysis_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Step 1: Select Folder",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        
        fluidRow(
          column(8, textInput(ns("folderPath"), "Folder with .txt files:", placeholder = "Select folder...")),
          column(4, br(), shinyDirButton(ns("browseDir"), "Browse...", "Select Folder"))
        ),
        br(),
        actionButton(ns("scanBtn"), "Scan Folder", class = "btn-info", style = "width: 100%;"),
        br(), br(),
        uiOutput(ns("folderContents"))
      ),
      
      box(
        title = "Step 2: Configure Analysis",
        status = "warning",
        solidHeader = TRUE,
        width = 6,
        
        selectInput(ns("sortMethod"), "Sort by:", 
                    choices = c("Filename" = "name", "Creation time" = "ctime", "Modified time" = "mtime")),
        
        numericInput(ns("maxWords"), "Max summary words:", value = 500, min = 50, max = 5000),
        
        checkboxInput(ns("useTimeout"), "Enable timeout", value = FALSE),
        conditionalPanel(
          condition = sprintf("input[\'%s\']", ns("useTimeout")),
          numericInput(ns("timeout"), "Timeout (seconds):", value = 180, min = 30, max = 600)
        ),
        
        textInput(ns("prompt"), "Prompt:", value = "Summarize the following combined text:"),
        br(),
        actionButton(ns("analyzeBtn"), "Analyze & Summarize", class = "btn-success btn-lg", style = "width: 100%;")
      )
    ),
    
    fluidRow(
      box(
        title = "Analysis Status",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        verbatimTextOutput(ns("status"))
      )
    ),
    
    fluidRow(
      box(
        title = "Analysis Results",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        
        textAreaInput(ns("results"), NULL, height = "400px", placeholder = "Results will appear here..."),
        
        fluidRow(
          column(8, textInput(ns("savePath"), "Save directory:", placeholder = "Select directory...")),
          column(2, br(), shinyDirButton(ns("browseSaveDir"), "Browse...", "Select Directory")),
          column(2, br(), actionButton(ns("saveBtn"), "Save", class = "btn-success", style = "width: 100%;"))
        )
      )
    )
  )
}