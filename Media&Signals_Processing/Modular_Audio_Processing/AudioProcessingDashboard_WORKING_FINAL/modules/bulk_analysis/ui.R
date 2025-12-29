bulk_analysis_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Step 1: Select Folder with Text Files",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        
        fluidRow(
          column(8,
                 textInput(ns("bulk_folder_path"),
                           "Folder containing .txt files:",
                           value = "",
                           placeholder = "Select folder with text files...")
          ),
          column(4,
                 br(),
                 shinyDirButton(ns("browseBulkFolder"),
                                "Browse...",
                                title = "Select Folder",
                                class = "btn-default",
                                icon = icon("folder"),
                                style = "width: 100%;")
          )
        ),
        br(),
        
        actionButton(ns("scanFolderBtn"),
                     "Scan Folder",
                     class = "btn-info",
                     icon = icon("search"),
                     style = "width: 100%;"),
        br(), br(),
        
        conditionalPanel(
          condition = paste0("output['", ns("folderScanned"), "']"),
          div(
            class = "reference-box",
            h5(icon("folder-open"), " Folder Contents:"),
            uiOutput(ns("folderContentsDisplay"))
          )
        )
      ),
      
      box(
        title = "Step 2: Configure Analysis Settings",
        status = "warning",
        solidHeader = TRUE,
        width = 6,
        
        selectInput(ns("sortMethod"),
                    "Sort files by:",
                    choices = c(
                      "Filename (alphabetically)" = "name",
                      "Creation time (oldest first)" = "ctime",
                      "Modification time (newest first)" = "mtime"
                    ),
                    selected = "name"),
        
        numericInput(ns("maxSummaryWords"),
                     "Maximum summary length (words):",
                     value = 500,
                     min = 50,
                     max = 5000,
                     step = 50),
        
        numericInput(ns("bulkAnalysisTimeout"),
                     "Request Timeout (seconds):",
                     value = 180,
                     min = 30,
                     max = 600,
                     step = 30),
        
        textInput(ns("analysisPrompt"),
                  "Custom prompt (optional):",
                  value = "Summarize the following combined text:",
                  placeholder = "Enter custom prompt..."),
        
        helpText("The app will concatenate all .txt files and send them to ChatGPT for analysis."),
        br(),
        
        h5("Save Concatenated Text:"),
        fluidRow(
          column(8,
                 textInput(ns("concat_output_path"),
                           "Output directory:",
                           placeholder = "Select directory for concatenated file...")
          ),
          column(4,
                 br(),
                 shinyDirButton(ns("browseConcatDir"),
                                "Browse...",
                                title = "Select Output Directory",
                                class = "btn-default",
                                icon = icon("folder"),
                                style = "width: 100%;")
          )
        ),
        br(),
        
        fluidRow(
          column(6,
                 actionButton(ns("downloadConcatBtn"),
                              "Download Concatenated Text",
                              class = "btn-info btn-lg",
                              icon = icon("download"),
                              style = "width: 100%;")
          ),
          column(6,
                 actionButton(ns("analyzeBtn"),
                              "Analyze & Summarize",
                              class = "btn-success btn-lg",
                              icon = icon("brain"),
                              style = "width: 100%;")
          )
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Analysis Status",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        
        verbatimTextOutput(ns("analysisStatus")),
        
        conditionalPanel(
          condition = "$(\'html\').hasClass(\'shiny-busy\')",
          div(
            style = "text-align: center; margin: 20px;",
            h4("Analyzing text..."),
            withSpinner(div(), type = 4, color = "#667eea")
          )
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Analysis Results",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        
        textAreaInput(ns("analysisSummary"),
                      label = NULL,
                      value = "",
                      placeholder = "Analysis summary will appear here...",
                      height = "400px",
                      resize = "vertical"),
        br(),
        
        fluidRow(
          column(6,
                 textInput(ns("summary_output_path"),
                           "Save directory:",
                           placeholder = "Select output directory...")
          ),
          column(3,
                 br(),
                 shinyDirButton(ns("browseSummaryDir"),
                                "Browse...",
                                title = "Select Output Directory",
                                class = "btn-default",
                                icon = icon("folder"),
                                style = "width: 100%;")
          ),
          column(3,
                 br(),
                 actionButton(ns("saveSummaryBtn"),
                              "Save Summary",
                              class = "btn-success",
                              icon = icon("save"),
                              style = "width: 100%;")
          )
        ),
        br(),
        
        textInput(ns("summary_filename"),
                  "Filename (without extension):",
                  value = paste0("summary_", format(Sys.time(), "%Y%m%d_%H%M%S")),
                  placeholder = "Enter filename...")
      )
    )
  )
}
