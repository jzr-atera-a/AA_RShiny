transcription_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      # Upload Section
      box(
        title = "Audio Upload",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        height = 550,
        
        fileInput(ns("audioFile"),
                  "Choose Audio File",
                  accept = c(".mp3", ".wav", ".m4a", ".flac", ".ogg"),
                  buttonLabel = "Browse...",
                  placeholder = "No file selected"),
        br(),
        
        conditionalPanel(
          condition = paste0("output['", ns("fileUploaded"), "']"),
          h5("File Information:"),
          verbatimTextOutput(ns("fileInfo")),
          br()
        ),
        
        h5("Transcription Settings:"),
        numericInput(ns("apiTimeout"),
                     "Request Timeout (seconds):",
                     value = 180,
                     min = 30,
                     max = 600,
                     step = 30),
        br(),
        
        actionButton(ns("transcribeBtn"),
                     "Transcribe Audio",
                     class = "btn-primary btn-lg",
                     style = "width: 100%;"),
        br(), br(),
        
        div(class = "timeout-warning",
            icon("exclamation-triangle"), " ",
            tags$strong("Timeout Guide:"),
            tags$ul(style = "margin: 5px 0 0 0; padding-left: 20px;",
                    tags$li("Small files (< 5MB): 60-120 seconds"),
                    tags$li("Medium files (5-15MB): 120-240 seconds"),
                    tags$li("Large files (15-25MB): 240-600 seconds")
            )
        ),
        br(),
        
        conditionalPanel(
          condition = "$(\'html\').hasClass(\'shiny-busy\')",
          div(
            style = "text-align: center;",
            h4("Processing audio..."),
            withSpinner(div(), type = 4, color = "#667eea")
          )
        )
      ),
      
      # Processing Status
      box(
        title = "Processing Status",
        status = "info",
        solidHeader = TRUE,
        width = 6,
        height = 550,
        
        verbatimTextOutput(ns("statusOutput"))
      )
    ),
    
    # Transcription Results
    fluidRow(
      box(
        title = "Transcription Results",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        height = 500,
        
        textAreaInput(ns("transcriptionText"),
                      label = NULL,
                      value = "",
                      placeholder = "Transcribed text will appear here...",
                      height = "300px",
                      resize = "vertical"),
        
        h5("Save Transcription:"),
        fluidRow(
          column(6,
                 textInput(ns("transcription_output_path"),
                           "Save directory:",
                           placeholder = "Select output directory...")
          ),
          column(3,
                 br(),
                 shinyDirButton(ns("browseTranscriptionDir"),
                                "Browse...",
                                title = "Select Output Directory",
                                class = "btn-default",
                                icon = icon("folder"),
                                style = "width: 100%;")
          ),
          column(3,
                 br(),
                 actionButton(ns("saveBtn"),
                              "Save Transcription",
                              class = "btn-success",
                              icon = icon("save"),
                              style = "width: 100%;")
          )
        ),
        br(),
        helpText("Filename will automatically match the audio file name.")
      )
    )
  )
}
