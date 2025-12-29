splitter_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Upload Audio File",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        fluidRow(
          column(6,
                 h4("Step 1: Upload Your Audio File"),
                 fileInput(ns("audio_file"), "Choose MP3 or WAV file:",
                           accept = c(".mp3", ".wav", ".MP3", ".WAV"),
                           buttonLabel = "Browse...",
                           placeholder = "No file selected"),
                 div(class = "info-box",
                     h5(icon("info-circle"), " Supported Formats:"),
                     tags$ul(
                       tags$li("MP3 files (.mp3)"),
                       tags$li("WAV files (.wav)"),
                       tags$li("Maximum file size: 100 MB")
                     )
                 )
          ),
          column(6,
                 h4("Step 2: Select Output Directory"),
                 fluidRow(
                   column(8,
                          textInput(ns("splitter_output_path"),
                                    "Output directory:",
                                    value = "",
                                    placeholder = "Select output directory...")
                   ),
                   column(4,
                          br(),
                          shinyDirButton(ns("browseSplitterDir"),
                                         "Browse...",
                                         title = "Select Output Directory",
                                         class = "btn-default",
                                         icon = icon("folder"),
                                         style = "width: 100%;")
                   )
                 ),
                 textInput(ns("output_folder"), "Output folder name:",
                           value = "split_audio_files",
                           placeholder = "Enter folder name"),
                 helpText("Files will be saved in a subfolder with this name.")
          )
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Split Settings",
        status = "info",
        solidHeader = TRUE,
        width = 6,
        
        radioButtons(ns("split_method"), "Split Method:",
                     choices = list(
                       "By Number of Files" = "num_files",
                       "By File Size" = "file_size"
                     ),
                     selected = "num_files"),
        
        conditionalPanel(
          condition = paste0("input['", ns("split_method"), "'] == 'num_files'"),
          numericInput(ns("num_splits"), "Number of files to split into:",
                       value = 2, min = 2, max = 50, step = 1),
          checkboxInput(ns("equal_duration"), "Split into equal duration segments",
                        value = TRUE),
          conditionalPanel(
            condition = paste0("input['", ns("equal_duration"), "'] == false"),
            helpText("Custom split points will be available after uploading the file")
          )
        ),
        
        conditionalPanel(
          condition = paste0("input['", ns("split_method"), "'] == 'file_size'"),
          numericInput(ns("splitter_max_size_mb"),
                       "Maximum file size (MB):",
                       value = 24,
                       min = 1,
                       max = 500,
                       step = 1),
          helpText("Audio will be split into multiple files, each not exceeding this size.")
        ),
        
        textInput(ns("output_prefix"), "Output file prefix:",
                  value = "segment", placeholder = "e.g., part_"),
        
        selectInput(ns("output_format"), "Output format:",
                    choices = list("WAV (recommended)" = "wav", "MP3" = "mp3"),
                    selected = "wav"),
        br(),
        
        actionButton(ns("split_audio"), "Split Audio",
                     class = "btn-success btn-lg", icon = icon("scissors"),
                     style = "font-size: 18px; padding: 12px 30px; width: 100%;")
      ),
      
      box(
        title = "Audio Information",
        status = "warning",
        solidHeader = TRUE,
        width = 6,
        
        verbatimTextOutput(ns("audio_info")),
        
        conditionalPanel(
          condition = paste0("output['", ns("show_duration_inputs"), "']"),
          h5("Custom Split Points (in seconds):"),
          uiOutput(ns("duration_inputs"))
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Processing Status & Results",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        
        h4("Processing Log:"),
        verbatimTextOutput(ns("process_log")),
        
        conditionalPanel(
          condition = paste0("output['", ns("show_results"), "']"),
          hr(),
          h4("Split Results:"),
          DT::DTOutput(ns("results_table")),
          br(),
          div(class = "reference-box",
              h4(icon("check-circle"), " Success!"),
              p("Your audio file has been split successfully. The files are saved in the folder: "),
              verbatimTextOutput(ns("output_location"), placeholder = FALSE)
          )
        ),
        
        conditionalPanel(
          condition = paste0("output['", ns("show_download"), "']"),
          br(),
          downloadButton(ns("download_zip"), "Download All Split Files as ZIP",
                         class = "btn-primary btn-lg",
                         icon = icon("download")),
          br(), br(),
          actionButton(ns("openSplitterFolderBtn"),
                       "Open Output Folder",
                       class = "btn-success",
                       icon = icon("folder-open"))
        )
      )
    )
  )
}
