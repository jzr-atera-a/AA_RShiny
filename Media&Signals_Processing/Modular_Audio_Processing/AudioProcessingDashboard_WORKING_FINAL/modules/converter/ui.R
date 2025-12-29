converter_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      # M4A Upload Section
      box(
        title = "M4A to MP3 Converter",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        height = 450,
        
        fileInput(ns("m4aFile"),
                  "Choose M4A File",
                  accept = c(".m4a"),
                  buttonLabel = "Browse...",
                  placeholder = "No M4A file selected"),
        br(),
        
        conditionalPanel(
          condition = paste0("output['", ns("m4aFileUploaded"), "']"),
          h5("File Information:"),
          verbatimTextOutput(ns("m4aFileInfo")),
          br()
        ),
        
        h5("Output Settings:"),
        fluidRow(
          column(8,
                 textInput(ns("outputPath"),
                           "Save to directory:",
                           value = "",
                           placeholder = "Select output directory...")
          ),
          column(4,
                 br(),
                 shinyDirButton(ns("browseOutputDir"),
                                "Browse...",
                                title = "Select Output Directory",
                                class = "btn-default",
                                icon = icon("folder"),
                                style = "width: 100%;")
          )
        ),
        
        fluidRow(
          column(12,
                 div(
                   class = "info-box",
                   h6("Auto-Split Feature:", style = "margin: 0; color: #667eea; font-weight: bold;"),
                   p("Files exceeding the specified maximum size will be automatically split into smaller parts",
                     style = "margin: 5px 0 0 0; color: #6b7280; font-size: 12px;")
                 )
          )
        ),
        br(),
        
        fluidRow(
          column(6,
                 selectInput(ns("mp3Quality"),
                             "Audio Quality:",
                             choices = c(
                               "High (320 kbps)" = "320k",
                               "Standard (192 kbps)" = "192k",
                               "Good (128 kbps)" = "128k",
                               "Basic (96 kbps)" = "96k"
                             ),
                             selected = "192k")
          ),
          column(6,
                 numericInput(ns("converter_max_size_mb"),
                              "Max file size (MB):",
                              value = 24,
                              min = 1,
                              max = 500,
                              step = 1)
          )
        ),
        
        fluidRow(
          column(12,
                 actionButton(ns("convertBtn"),
                              "Convert to MP3",
                              class = "btn-primary btn-lg",
                              style = "width: 100%;")
          )
        ),
        br(),
        
        conditionalPanel(
          condition = "$(\'html\').hasClass(\'shiny-busy\')",
          div(
            style = "text-align: center;",
            h4("Converting audio..."),
            withSpinner(div(), type = 4, color = "#667eea")
          )
        )
      ),
      
      # Conversion Status and Results
      box(
        title = "Conversion Status",
        status = "success",
        solidHeader = TRUE,
        width = 6,
        height = 450,
        
        verbatimTextOutput(ns("conversionStatus")),
        br(),
        
        conditionalPanel(
          condition = paste0("output['", ns("conversionComplete"), "']"),
          div(
            style = "text-align: center; padding: 20px;",
            h4("Conversion Completed Successfully!", style = "color: #11998e;"),
            br(),
            h5("File Details:"),
            verbatimTextOutput(ns("convertedFileInfo")),
            br(),
            actionButton(ns("openConverterFolderBtn"),
                         "Open Output Folder",
                         class = "btn-success",
                         icon = icon("folder-open"))
          )
        )
      )
    ),
    
    # Conversion History
    fluidRow(
      box(
        title = "Conversion History",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        withSpinner(DT::dataTableOutput(ns("conversionHistoryTable")))
      )
    )
  )
}
