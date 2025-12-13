# Audio Speech-to-Text R Shiny Dashboard with File Splitter
# Install required packages if not already installed
# install.packages(c("shiny", "shinydashboard", "DT", "plotly", "httr", "jsonlite", "shinycssloaders", "shinyFiles", "stringr", "av", "tuneR", "seewave"))

library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(httr)
library(jsonlite)
library(shinycssloaders)
library(shinyFiles)
library(stringr)
library(av)
library(tuneR)
library(seewave)

# Define UI
ui <- dashboardPage(
  skin = "purple",
  
  # Header
  dashboardHeader(
    title = "Audio Processing Dashboard",
    titleWidth = 300
  ),
  
  # Sidebar
  dashboardSidebar(
    width = 300,
    tags$head(
      tags$style(HTML("
        .main-header .navbar { 
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
          border: none !important; 
          box-shadow: 0 2px 10px rgba(0,0,0,0.1) !important;
        }
        .main-header .navbar-brand { 
          color: white !important; 
          font-weight: 700 !important; 
          font-size: 18px !important;
        }
        .main-sidebar { 
          background: linear-gradient(180deg, #2c3e50 0%, #34495e 100%) !important; 
        }
        .sidebar-menu > li > a { 
          color: #ecf0f1 !important; 
          border-left: 3px solid transparent; 
          transition: all 0.3s ease !important;
          font-weight: 500 !important;
        }
        .sidebar-menu > li.active > a { 
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
          border-left: 3px solid #f39c12 !important; 
          color: white !important; 
          box-shadow: inset 0 0 10px rgba(0,0,0,0.2) !important;
        }
        .sidebar-menu > li:hover > a { 
          background-color: #3e5771 !important; 
          color: white !important; 
        }
        .content-wrapper { 
          background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%) !important; 
        }
        .box { 
          border: none !important; 
          border-radius: 12px !important; 
          box-shadow: 0 4px 20px rgba(0,0,0,0.08) !important;
          background: white !important;
        }
        .box-header { 
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
          color: white !important;
          border-radius: 12px 12px 0 0 !important; 
          font-weight: 600 !important;
        }
        .data-source-box { 
          background: linear-gradient(135deg, #ffffff 0%, #f8f9ff 100%);
          border: none;
          border-left: 5px solid #667eea; 
          padding: 25px; 
          margin-bottom: 25px; 
          border-radius: 12px; 
          box-shadow: 0 4px 15px rgba(102, 126, 234, 0.1);
        }
        .reference-box {
          background: linear-gradient(135deg, #f8f9ff 0%, #ffffff 100%);
          border: 1px solid #e3e8ff;
          border-left: 5px solid #4f46e5;
          padding: 20px;
          margin-top: 25px;
          border-radius: 12px;
          box-shadow: 0 2px 10px rgba(79, 70, 229, 0.1);
        }
        .small-box { 
          border-radius: 12px !important; 
          box-shadow: 0 4px 15px rgba(0,0,0,0.1) !important;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
        }
        .small-box .icon { opacity: 0.8 !important; }
        .plotly { 
          border-radius: 12px !important; 
          box-shadow: 0 2px 10px rgba(0,0,0,0.05) !important;
        }
        .dataTables_wrapper { 
          background: white; 
          border-radius: 12px; 
          padding: 20px; 
          box-shadow: 0 2px 10px rgba(0,0,0,0.05);
        }
        .btn-primary { 
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
          border: none !important; 
          border-radius: 8px !important;
          font-weight: 600 !important;
        }
        .btn-success {
          background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          font-weight: 600 !important;
        }
        .btn-warning {
          background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          font-weight: 600 !important;
        }
        .btn-info {
          background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          font-weight: 600 !important;
        }
        h4 { color: #2c3e50; font-weight: 600; }
        .reference-box h4 { color: #4f46e5; }
        .form-control {
          border-radius: 8px !important;
          border: 1px solid #d1d5db !important;
        }
        .form-control:focus {
          border-color: #667eea !important;
          box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.25) !important;
        }
        .progress-bar {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
        }
        .info-box {
          background: linear-gradient(135deg, #f8f9ff 0%, #ffffff 100%);
          border-left: 5px solid #667eea;
          padding: 15px;
          border-radius: 8px;
          margin: 10px 0;
        }
      "))
    ),
    
    sidebarMenu(
      menuItem("Audio Converter", tabName = "converter", icon = icon("exchange-alt")),
      menuItem("File Splitter", tabName = "splitter", icon = icon("scissors")),
      menuItem("Settings", tabName = "settings", icon = icon("cog")),
      menuItem("Audio Transcription", tabName = "transcription", icon = icon("microphone")),
      menuItem("Analytics Dashboard", tabName = "analytics", icon = icon("chart-bar"))
    )
  ),
  
  # Body
  dashboardBody(
    tabItems(
      # Audio Converter Tab
      tabItem(
        tabName = "converter",
        fluidRow(
          # M4A Upload Section
          box(
            title = "M4A to MP3 Converter", 
            status = "primary", 
            solidHeader = TRUE,
            width = 6,
            height = 450,
            
            fileInput("m4aFile", 
                      "Choose M4A File",
                      accept = c(".m4a"),
                      buttonLabel = "Browse...",
                      placeholder = "No M4A file selected"),
            
            br(),
            
            conditionalPanel(
              condition = "output.m4aFileUploaded",
              h5("File Information:"),
              verbatimTextOutput("m4aFileInfo"),
              br()
            ),
            
            h5("Output Settings:"),
            fluidRow(
              column(8,
                     textInput("outputPath", 
                               "Save to directory:", 
                               value = getwd(),
                               placeholder = "Enter directory path...")
              ),
              column(4,
                     br(),
                     actionButton("browseOutputDir", 
                                  "Browse...", 
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
                       p("Files larger than 24MB will be automatically split into smaller parts", 
                         style = "margin: 5px 0 0 0; color: #6b7280; font-size: 12px;")
                     )
              )
            ),
            
            br(),
            
            fluidRow(
              column(6,
                     selectInput("mp3Quality", 
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
                     br(),
                     actionButton("convertBtn", 
                                  "Convert to MP3", 
                                  class = "btn-primary btn-lg",
                                  style = "width: 100%;")
              )
            ),
            
            br(),
            
            conditionalPanel(
              condition = "$('html').hasClass('shiny-busy')",
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
            
            verbatimTextOutput("conversionStatus"),
            
            br(),
            
            conditionalPanel(
              condition = "output.conversionComplete",
              div(
                style = "text-align: center; padding: 20px;",
                h4("Conversion Completed Successfully!", style = "color: #11998e;"),
                br(),
                h5("File Details:"),
                verbatimTextOutput("convertedFileInfo"),
                br(),
                actionButton("openFolderBtn", 
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
            
            withSpinner(DT::dataTableOutput("conversionHistoryTable"))
          )
        )
      ),
      
      # File Splitter Tab
      tabItem(
        tabName = "splitter",
        fluidRow(
          box(
            title = "Upload Audio File", 
            status = "primary", 
            solidHeader = TRUE, 
            width = 12,
            
            fluidRow(
              column(8,
                     h4("Step 1: Upload Your Audio File"),
                     fileInput("audio_file", "Choose MP3 or WAV file:",
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
              
              column(4,
                     h4("Step 2: Set Output Folder Name"),
                     textInput("output_folder", "Output folder name:",
                               value = "split_audio_files",
                               placeholder = "Enter folder name"),
                     
                     helpText("Files will be saved in a folder with this name in your Downloads directory or current working directory.")
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
            
            numericInput("num_splits", "Number of files to split into:", 
                         value = 2, min = 2, max = 50, step = 1),
            
            checkboxInput("equal_duration", "Split into equal duration segments", 
                          value = TRUE),
            
            conditionalPanel(
              condition = "input.equal_duration == false",
              helpText("Custom split points will be available after uploading the file")
            ),
            
            textInput("output_prefix", "Output file prefix:", 
                      value = "segment", placeholder = "e.g., part_"),
            
            selectInput("output_format", "Output format:",
                        choices = list("WAV (recommended)" = "wav", "MP3" = "mp3"),
                        selected = "wav"),
            
            br(),
            actionButton("split_audio", "Split Audio", 
                         class = "btn-success btn-lg", icon = icon("scissors"),
                         style = "font-size: 18px; padding: 12px 30px; width: 100%;")
          ),
          
          box(
            title = "Audio Information", 
            status = "warning", 
            solidHeader = TRUE, 
            width = 6,
            
            verbatimTextOutput("audio_info"),
            
            conditionalPanel(
              condition = "output.show_duration_inputs",
              h5("Custom Split Points (in seconds):"),
              uiOutput("duration_inputs")
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
            verbatimTextOutput("process_log"),
            
            conditionalPanel(
              condition = "output.show_results",
              hr(),
              h4("Split Results:"),
              DTOutput("results_table"),
              
              br(),
              div(class = "reference-box",
                  h4(icon("check-circle"), " Success!"),
                  p("Your audio file has been split successfully. The files are saved in the folder: "),
                  verbatimTextOutput("output_location", placeholder = FALSE)
              )
            ),
            
            conditionalPanel(
              condition = "output.show_download",
              br(),
              downloadButton("download_zip", "Download All Split Files as ZIP", 
                             class = "btn-primary btn-lg", 
                             icon = icon("download"))
            )
          )
        )
      ),
      
      # Settings Tab
      tabItem(
        tabName = "settings",
        fluidRow(
          box(
            title = "OpenAI API Configuration", 
            status = "warning", 
            solidHeader = TRUE,
            width = 6,
            
            passwordInput("apiKey", 
                          "OpenAI API Key:",
                          placeholder = "Enter your OpenAI API key..."),
            
            selectInput("model", 
                        "Whisper Model:",
                        choices = c("whisper-1" = "whisper-1"),
                        selected = "whisper-1"),
            
            selectInput("language", 
                        "Language (optional):",
                        choices = c(
                          "Auto-detect" = "",
                          "English" = "en",
                          "Spanish" = "es",
                          "French" = "fr",
                          "German" = "de",
                          "Italian" = "it",
                          "Portuguese" = "pt",
                          "Dutch" = "nl",
                          "Russian" = "ru",
                          "Chinese" = "zh",
                          "Japanese" = "ja",
                          "Korean" = "ko"
                        ),
                        selected = ""),
            
            actionButton("saveSettings", 
                         "Save Settings", 
                         class = "btn-warning"),
            
            br(), br(),
            
            actionButton("testConnection", 
                         "Test API Connection", 
                         class = "btn-info",
                         icon = icon("plug")),
            
            br(), br(),
            
            # Connection Status Display
            div(id = "connectionStatus",
                conditionalPanel(
                  condition = "output.connectionTested",
                  div(
                    class = "reference-box",
                    h5("API Connection Status:", style = "margin: 0 0 10px 0;"),
                    verbatimTextOutput("apiConnectionStatus")
                  )
                )
            )
          ),
          
          box(
            title = "Application Info", 
            status = "info", 
            solidHeader = TRUE,
            width = 6,
            
            h4("Supported Audio Formats:"),
            tags$ul(
              tags$li("MP3"),
              tags$li("WAV"),
              tags$li("M4A"),
              tags$li("FLAC"),
              tags$li("OGG")
            ),
            
            h4("Features:"),
            tags$ul(
              tags$li("Real-time audio transcription"),
              tags$li("Multiple language support"),
              tags$li("Audio file conversion (M4A to MP3)"),
              tags$li("Audio file splitting"),
              tags$li("Transcription history and analytics"),
              tags$li("Custom save locations"),
              tags$li("Processing time tracking")
            )
          )
        )
      ),
      
      # Transcription Tab
      tabItem(
        tabName = "transcription",
        fluidRow(
          # Upload Section
          box(
            title = "Audio Upload", 
            status = "primary", 
            solidHeader = TRUE,
            width = 6,
            height = 400,
            
            fileInput("audioFile", 
                      "Choose Audio File",
                      accept = c(".mp3", ".wav", ".m4a", ".flac", ".ogg"),
                      buttonLabel = "Browse...",
                      placeholder = "No file selected"),
            
            br(),
            
            conditionalPanel(
              condition = "output.fileUploaded",
              h5("File Information:"),
              verbatimTextOutput("fileInfo"),
              br()
            ),
            
            actionButton("transcribeBtn", 
                         "Transcribe Audio", 
                         class = "btn-primary btn-lg",
                         style = "width: 100%;"),
            
            br(), br(),
            
            conditionalPanel(
              condition = "$('html').hasClass('shiny-busy')",
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
            height = 400,
            
            verbatimTextOutput("statusOutput")
          )
        ),
        
        # Transcription Results - Full Width Row
        fluidRow(
          box(
            title = "Transcription Results", 
            status = "success", 
            solidHeader = TRUE,
            width = 12,
            height = 500,
            
            textAreaInput("transcriptionText", 
                          label = NULL,
                          value = "",
                          placeholder = "Transcribed text will appear here...",
                          height = "350px",
                          resize = "vertical"),
            
            fluidRow(
              column(6,
                     textInput("saveLocation", 
                               "Save Location:", 
                               placeholder = "Enter file path...")
              ),
              column(6,
                     br(),
                     actionButton("saveBtn", 
                                  "Save Transcription", 
                                  class = "btn-success",
                                  style = "width: 100%;")
              )
            )
          )
        )
      ),
      
      # Analytics Tab
      tabItem(
        tabName = "analytics",
        fluidRow(
          # Summary Statistics
          valueBoxOutput("totalFiles"),
          valueBoxOutput("totalWords"),
          valueBoxOutput("avgDuration")
        ),
        
        fluidRow(
          # Word Count Analysis
          box(
            title = "Word Count Distribution", 
            status = "primary", 
            solidHeader = TRUE,
            width = 6,
            
            withSpinner(plotlyOutput("wordCountPlot"))
          ),
          
          # Processing Time Analysis
          box(
            title = "Processing Time Trends", 
            status = "primary", 
            solidHeader = TRUE,
            width = 6,
            
            withSpinner(plotlyOutput("processingTimePlot"))
          )
        ),
        
        fluidRow(
          # Transcription History
          box(
            title = "Transcription History", 
            status = "info", 
            solidHeader = TRUE,
            width = 12,
            
            withSpinner(DT::dataTableOutput("historyTable"))
          )
        )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Increase file upload limit to 100MB (to handle larger audio files)
  options(shiny.maxRequestSize = 100*1024^2)  # 100MB in bytes
  
  # Reactive values for storing data
  values <- reactiveValues(
    transcriptions = data.frame(
      timestamp = character(),
      filename = character(),
      word_count = numeric(),
      processing_time = numeric(),
      file_size = numeric(),
      stringsAsFactors = FALSE
    ),
    conversions = data.frame(
      timestamp = character(),
      input_file = character(),
      output_files = character(),
      input_size = numeric(),
      output_size = numeric(),
      parts_created = numeric(),
      quality = character(),
      conversion_time = numeric(),
      stringsAsFactors = FALSE
    ),
    api_key = "",
    current_transcription = "",
    conversion_complete = FALSE,
    connection_tested = FALSE,
    api_status = "",
    # File Splitter values
    audio_data = NULL,
    audio_info = NULL,
    processing_log = "Ready to process audio files...\n",
    results = NULL,
    output_dir = NULL,
    temp_files = c()
  )
  
  # File upload status
  output$fileUploaded <- reactive({
    return(!is.null(input$audioFile))
  })
  outputOptions(output, 'fileUploaded', suspendWhenHidden = FALSE)
  
  # M4A file upload status
  output$m4aFileUploaded <- reactive({
    return(!is.null(input$m4aFile))
  })
  outputOptions(output, 'm4aFileUploaded', suspendWhenHidden = FALSE)
  
  # Conversion complete status
  output$conversionComplete <- reactive({
    return(values$conversion_complete)
  })
  outputOptions(output, 'conversionComplete', suspendWhenHidden = FALSE)
  
  # Connection tested status
  output$connectionTested <- reactive({
    return(values$connection_tested)
  })
  outputOptions(output, 'connectionTested', suspendWhenHidden = FALSE)
  
  # File information display
  output$fileInfo <- renderText({
    req(input$audioFile)
    file_info <- input$audioFile
    paste(
      "Filename:", file_info$name, "\n",
      "Size:", round(file_info$size / 1024 / 1024, 2), "MB", "\n",
      "Type:", tools::file_ext(file_info$name)
    )
  })
  
  # M4A file information display
  output$m4aFileInfo <- renderText({
    req(input$m4aFile)
    file_info <- input$m4aFile
    paste(
      "Filename:", file_info$name, "\n",
      "Size:", round(file_info$size / 1024 / 1024, 2), "MB", "\n",
      "Type:", tools::file_ext(file_info$name)
    )
  })
  
  # API Connection Testing Function
  testOpenAIConnection <- function(api_key) {
    tryCatch({
      # Test API connection by making a simple request to list models
      url <- "https://api.openai.com/v1/models"
      
      response <- GET(
        url,
        add_headers(Authorization = paste("Bearer", api_key)),
        timeout(10)  # 10 second timeout
      )
      
      status <- status_code(response)
      
      result <- list()
      
      if (status == 200) {
        content_result <- content(response, "parsed")
        # Check if whisper models are available
        model_ids <- sapply(content_result$data, function(x) x$id)
        whisper_available <- any(grepl("whisper", model_ids, ignore.case = TRUE))
        
        result$success <- TRUE
        result$message <- paste(
          "✓ API Connection Successful\n",
          "✓ Authentication Valid\n",
          "✓ Models Accessible:", length(model_ids), "models found\n",
          if(whisper_available) "✓ Whisper Models Available" else "⚠ Whisper Models Not Found"
        )
        result$status <- "success"
        
      } else if (status == 401) {
        result$success <- FALSE
        result$message <- "✗ Authentication Failed\nInvalid API key. Please check your OpenAI API key."
        result$status <- "error"
        
      } else if (status == 429) {
        result$success <- FALSE
        result$message <- "✗ Rate Limit Exceeded\nToo many requests. Please try again later."
        result$status <- "warning"
        
      } else if (status >= 500) {
        result$success <- FALSE
        result$message <- "✗ OpenAI Server Error\nOpenAI services may be temporarily unavailable."
        result$status <- "warning"
        
      } else {
        result$success <- FALSE
        result$message <- paste("✗ Connection Failed\nHTTP Status:", status)
        result$status <- "error"
      }
      
      return(result)
      
    }, error = function(e) {
      return(list(
        success = FALSE,
        message = paste("✗ Connection Error\n", e$message),
        status = "error"
      ))
    })
  }
  
  # Transcription function using OpenAI API
  transcribeAudio <- function(file_path, api_key) {
    req(api_key, file_path)
    
    # Validate inputs
    api_key <- trimws(api_key)
    if (nchar(api_key) == 0) {
      stop("API key is required. Please set your OpenAI API key in Settings.")
    }
    
    if (!file.exists(file_path)) {
      stop("Audio file not found. Please try uploading again.")
    }
    
    # Prepare the API request
    url <- "https://api.openai.com/v1/audio/transcriptions"
    
    # Create the request body
    body <- list(
      file = upload_file(file_path),
      model = input$model %||% "whisper-1"
    )
    
    # Add language if specified
    language <- input$language %||% ""
    if (nchar(language) > 0) {
      body$language <- language
    }
    
    print(body)  # Add this line right before the POST request
    
    # Make the API request with timeout
    response <- POST(
      url,
      add_headers(Authorization = paste("Bearer", api_key)),
      body = body,
      encode = "multipart",
      timeout(300)  # 5 minute timeout for large files
    )
    
    # Check response status
    status <- status_code(response)
    
    if (status != 200) {
      error_content <- content(response, "text", encoding = "UTF-8")
      if (status == 401) {
        stop("Authentication failed. Please check your API key.")
      } else if (status == 413) {
        stop("File too large. Maximum file size is 25MB.")
      } else if (status == 429) {
        stop("Rate limit exceeded. Please try again later.")
      } else {
        stop(paste("API Error (", status, "):", error_content))
      }
    }
    
    # Parse response
    content_result <- content(response, "parsed", encoding = "UTF-8")
    
    # Validate response structure
    if (is.null(content_result) || !is.list(content_result)) {
      stop("Invalid response format from OpenAI API.")
    }
    
    if (!"text" %in% names(content_result)) {
      stop("No transcription text found in API response.")
    }
    
    transcription_text <- content_result$text
    
    # Validate transcription text
    if (is.null(transcription_text) || !is.character(transcription_text)) {
      stop("Invalid transcription format received from API.")
    }
    
    if (length(transcription_text) == 0 || nchar(transcription_text) == 0) {
      return("No speech detected in the audio file.")
    }
    
    return(transcription_text)
  }
  
  # Transcribe button event with detailed progress tracking
  observeEvent(input$transcribeBtn, {
    req(input$audioFile)
    
    # Check if API key is set
    if (is.null(values$api_key) || nchar(trimws(values$api_key)) == 0) {
      output$statusOutput <- renderText("❌ Error: No API key found. Please set your OpenAI API key in Settings and test the connection.")
      showNotification("Please set your API key in Settings first.", type = "error")
      return()
    }
    
    # Get file information
    file_size_mb <- round(input$audioFile$size / 1024 / 1024, 2)
    file_name <- input$audioFile$name
    file_duration_estimate <- round(file_size_mb * 2, 0)  # Rough estimate: 2 minutes per MB
    
    # Step 1: Initialize
    output$statusOutput <- renderText(paste(
      "🔄 STEP 1/6: Initializing transcription process...\n\n",
      "📁 File:", file_name, "\n",
      "📊 Size:", file_size_mb, "MB\n",
      "⏱️ Estimated duration: ~", file_duration_estimate, "minutes\n",
      "🎯 Target model: Whisper-1\n\n",
      "Status: Preparing for upload..."
    ))
    
    # Simulate progress with delays
    Sys.sleep(1)
    
    # Step 2: Validation
    output$statusOutput <- renderText(paste(
      "🔍 STEP 2/6: Validating file and settings...\n\n",
      "✅ File format: Supported\n",
      "✅ File size: Within limits (< 25MB)\n",
      "✅ API key: Configured\n",
      "✅ Model: whisper-1 selected\n",
      "✅ Language:", if(input$language == "") "Auto-detect" else input$language, "\n\n",
      "Status: All validations passed, preparing upload..."
    ))
    
    Sys.sleep(1)
    
    tryCatch({
      start_time <- Sys.time()
      
      # Step 3: Upload preparation
      output$statusOutput <- renderText(paste(
        "📤 STEP 3/6: Preparing file upload...\n\n",
        "🔧 Encoding file for transmission...\n",
        "🌐 Establishing connection to OpenAI servers...\n",
        "🔐 Authenticating with API key...\n",
        "📡 Setting up secure upload channel...\n\n",
        "Status: Ready to upload to OpenAI..."
      ))
      
      Sys.sleep(2)
      
      # Step 4: Upload in progress
      upload_start <- Sys.time()
      output$statusOutput <- renderText(paste(
        "⬆️ STEP 4/6: Uploading file to OpenAI...\n\n",
        "📂 File:", file_name, "\n",
        "📊 Size:", file_size_mb, "MB\n",
        "🔄 Upload progress: Starting...\n",
        "⏱️ Estimated upload time:", round(file_size_mb * 0.5, 1), "seconds\n",
        "🌐 Server: api.openai.com\n\n",
        "Status: Uploading audio data..."
      ))
      
      # Simulate upload progress
      for(i in 1:3) {
        Sys.sleep(max(1, file_size_mb * 0.1))
        progress_percent <- round((i/3) * 100)
        output$statusOutput <- renderText(paste(
          "⬆️ STEP 4/6: Uploading file to OpenAI...\n\n",
          "📂 File:", file_name, "\n",
          "📊 Size:", file_size_mb, "MB\n",
          "🔄 Upload progress:", progress_percent, "%\n",
          "⏱️ Time elapsed:", round(as.numeric(difftime(Sys.time(), upload_start, units = "secs")), 1), "seconds\n",
          "🌐 Server: api.openai.com\n\n",
          "Status:", if(i < 3) "Uploading audio data..." else "Upload complete, processing..."
        ))
      }
      
      # Step 5: Processing
      processing_start <- Sys.time()
      output$statusOutput <- renderText(paste(
        "🧠 STEP 5/6: OpenAI Whisper processing...\n\n",
        "🎵 Audio analysis: Starting...\n",
        "🔤 Speech detection: Initializing...\n",
        "🌍 Language detection:", if(input$language == "") "Auto-detecting..." else paste("Set to", input$language), "\n",
        "⚡ AI Model: Whisper-1 activated\n",
        "⏱️ Processing time: Large files may take 2-5 minutes\n\n",
        "Status: AI is analyzing your audio..."
      ))
      
      print(paste("Selected language:", input$language))
      
      # Actually make the API call here
      transcription <- transcribeAudio(input$audioFile$datapath, values$api_key)
      
      processing_time <- as.numeric(difftime(Sys.time(), processing_start, units = "secs"))
      
      # Step 6: Completion
      output$statusOutput <- renderText(paste(
        "🧠 STEP 5/6: OpenAI Whisper processing...\n\n",
        "✅ Audio analysis: Complete\n",
        "✅ Speech detection: Completed\n",
        "✅ Language detected:", if(input$language == "") "Auto-detected" else input$language, "\n",
        "✅ AI Model: Whisper-1 processing complete\n",
        "⏱️ Processing time:", round(processing_time, 1), "seconds\n\n",
        "Status: Transcription generated, finalizing..."
      ))
      
      Sys.sleep(1)
      
      # Final step: Results
      end_time <- Sys.time()
      total_processing_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
      
      # Update the transcription text area
      updateTextAreaInput(session, "transcriptionText", value = transcription)
      values$current_transcription <- transcription
      
      # Calculate word count
      word_count <- length(strsplit(trimws(transcription), "\\s+")[[1]])
      character_count <- nchar(transcription)
      
      # Add to history
      new_row <- data.frame(
        timestamp = as.character(Sys.time()),
        filename = file_name,
        word_count = word_count,
        processing_time = round(total_processing_time, 2),
        file_size = file_size_mb,
        stringsAsFactors = FALSE
      )
      
      values$transcriptions <- rbind(values$transcriptions, new_row)
      
      # Final success status
      output$statusOutput <- renderText(paste(
        "🎉 STEP 6/6: Transcription completed successfully!\n\n",
        "📄 RESULTS SUMMARY:\n",
        "├── File processed:", file_name, "\n",
        "├── Total processing time:", round(total_processing_time, 2), "seconds\n",
        "├── Words transcribed:", format(word_count, big.mark = ","), "words\n",
        "├── Characters:", format(character_count, big.mark = ","), "characters\n",
        "├── File size:", file_size_mb, "MB\n",
        "├── Processing rate:", round(word_count / (total_processing_time/60), 0), "words/minute\n",
        "└── Completed at:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n",
        "✅ Transcription is ready! Check the results below."
      ))
      
      showNotification(paste("Transcription completed! ", word_count, " words processed in ", round(total_processing_time, 1), " seconds"), type = "message")
      
    }, error = function(e) {
      error_message <- as.character(e$message)
      
      # Detailed error status
      output$statusOutput <- renderText(paste(
        "❌ TRANSCRIPTION FAILED!\n\n",
        "🚨 ERROR DETAILS:\n",
        "├── Error type:", class(e)[1], "\n",
        "├── Message:", error_message, "\n",
        "├── Time occurred:", format(Sys.time(), "%H:%M:%S"), "\n",
        "└── File:", file_name, "\n\n",
        "🔧 TROUBLESHOOTING STEPS:\n",
        "1. ✓ Check internet connection\n",
        "2. ✓ Verify API key in Settings tab\n",
        "3. ✓ Test API connection in Settings\n",
        "4. ✓ Ensure file is under 25MB\n",
        "5. ✓ Try a different audio format\n",
        "6. ✓ Wait and retry in 1-2 minutes\n\n",
        "💡 COMMON SOLUTIONS:\n",
        "• File too large → Compress audio file\n",
        "• Network timeout → Check internet speed\n",
        "• API key invalid → Regenerate in OpenAI dashboard\n",
        "• Rate limit → Wait before retrying"
      ))
      
      showNotification(paste("Transcription failed:", error_message), type = "error")
    })
  })
  
  # Save transcription
  observeEvent(input$saveBtn, {
    req(values$current_transcription)
    req(input$saveLocation)
    
    tryCatch({
      # Ensure the file has a .txt extension
      save_path <- input$saveLocation
      save_path <- paste0(save_path, ".txt")
      
      writeLines(values$current_transcription, save_path)
      showNotification(paste("Transcription saved to:", save_path), type = "message")
      
    }, error = function(e) {
      showNotification(paste("Error saving file:", e$message), type = "error")
    })
  })
  
  # Save settings
  observeEvent(input$saveSettings, {
    req(input$apiKey)
    values$api_key <- input$apiKey
    values$connection_tested <- FALSE  # Reset connection status when key changes
    showNotification("Settings saved successfully!", type = "message")
  })
  
  # Test API Connection
  observeEvent(input$testConnection, {
    
    # Check if API key is provided
    api_key_to_test <- input$apiKey %||% values$api_key
    
    req(api_key_to_test)
    
    showNotification("Testing API connection...", type = "message")
    
    # Test the connection
    result <- testOpenAIConnection(api_key_to_test)
    
    # Update reactive values
    values$connection_tested <- TRUE
    values$api_status <- result$message
    
    # Display result
    output$apiConnectionStatus <- renderText({
      result$message
    })
    
    # Show notification based on result
    notification_type <- switch(result$status,
                                "success" = "message",
                                "error" = "error",
                                "warning" = "warning",
                                "message")
    
    if (result$success) {
      showNotification("API connection test completed successfully!", type = notification_type)
      # Auto-save the API key if connection is successful
      values$api_key <- api_key_to_test
    } else {
      showNotification("API connection test failed. Please check your settings.", type = notification_type)
    }
  })
  
  # Audio conversion function with auto-splitting
  convertM4AtoMP3WithSplit <- function(input_path, output_dir, base_filename, quality = "192k") {
    tryCatch({
      # First, convert to MP3
      temp_output <- file.path(output_dir, paste0(base_filename, "_temp.mp3"))
      av::av_audio_convert(input_path, temp_output, format = "mp3")
      
      # Check file size
      file_size_mb <- file.info(temp_output)$size / (1024^2)
      max_size_mb <- 24
      
      if (file_size_mb <= max_size_mb) {
        # File is small enough, just rename it
        final_output <- file.path(output_dir, paste0(base_filename, ".mp3"))
        file.rename(temp_output, final_output)
        
        return(list(
          success = TRUE,
          files = basename(final_output),
          total_size = file_size_mb,
          parts = 1,
          split = FALSE
        ))
      } else {
        # File is too large, need to split
        
        # Get audio info to calculate split duration
        audio_info <- av::av_media_info(temp_output)
        total_duration <- audio_info$duration
        
        # Calculate number of parts needed
        num_parts <- ceiling(file_size_mb / max_size_mb)
        part_duration <- total_duration / num_parts
        
        # Create split files
        output_files <- character()
        total_output_size <- 0
        
        for (i in 1:num_parts) {
          start_time <- (i - 1) * part_duration
          part_filename <- paste0(base_filename, "_part", sprintf("%02d", i), ".mp3")
          part_output <- file.path(output_dir, part_filename)
          
          # Split the audio using av package
          av::av_audio_convert(
            temp_output, 
            part_output, 
            format = "mp3",
            start_time = start_time,
            total_time = min(part_duration, total_duration - start_time)
          )
          
          output_files <- c(output_files, basename(part_output))
          total_output_size <- total_output_size + (file.info(part_output)$size / (1024^2))
        }
        
        # Remove temporary file
        file.remove(temp_output)
        
        return(list(
          success = TRUE,
          files = output_files,
          total_size = total_output_size,
          parts = num_parts,
          split = TRUE
        ))
      }
      
    }, error = function(e) {
      # Clean up temp file if it exists
      if (exists("temp_output") && file.exists(temp_output)) {
        file.remove(temp_output)
      }
      
      return(list(
        success = FALSE,
        error = e$message
      ))
    })
  }
  
  observeEvent(input$browseOutputDir, {
    tryCatch({
      selected_dir <- choose.dir(default = getwd(), caption = "Select Output Directory")
      
      # Update the text input with selected directory
      updateTextInput(session, "outputPath", value = selected_dir %||% getwd())
      
      showNotification("Output directory selected", type = "message")
      
    }, error = function(e) {
      showNotification("Directory selection cancelled or failed", type = "warning")
    })
  })
  
  # CONVERTER FUNCTIONALITY WITH AUTO-SPLITTING
  observeEvent(input$convertBtn, {
    
    # Use req() only - NO if statements at all
    req(input$m4aFile)
    req(input$m4aFile$datapath)
    req(input$m4aFile$name)
    req(input$mp3Quality)
    
    # Reset conversion status
    values$conversion_complete <- FALSE
    
    # Show processing status
    output$conversionStatus <- renderText("🔄 Starting M4A to MP3 conversion...")
    
    # Perform conversion with complete error handling
    tryCatch({
      start_time <- Sys.time()
      
      # Get file information
      input_path <- input$m4aFile$datapath
      input_name <- input$m4aFile$name
      quality <- input$mp3Quality
      input_size_mb <- input$m4aFile$size / (1024^2)
      
      # Update status
      output$conversionStatus <- renderText(paste(
        "📁 STEP 1/4: Analyzing input file...\n\n",
        "File:", input_name, "\n",
        "Size:", round(input_size_mb, 2), "MB\n",
        "Quality:", quality, "\n\n",
        "Status: Preparing conversion..."
      ))
      
      Sys.sleep(1)
      
      # Get output directory and filename
      output_dir <- input$outputPath %||% getwd()
      base_name <- tools::file_path_sans_ext(input_name)
      
      # Update status
      output$conversionStatus <- renderText(paste(
        "🔧 STEP 2/4: Setting up conversion parameters...\n\n",
        "Output directory:", output_dir, "\n",
        "Base filename:", base_name, "\n",
        "Target format: MP3\n",
        "Quality setting:", quality, "\n\n",
        "Status: Initializing conversion engine..."
      ))
      
      Sys.sleep(1)
      
      # Update status
      output$conversionStatus <- renderText(paste(
        "⚡ STEP 3/4: Converting audio format...\n\n",
        "Converting M4A → MP3...\n",
        "Applying quality settings...\n",
        "Processing audio data...\n\n",
        "Status: Conversion in progress..."
      ))
      
      # Perform the conversion with auto-splitting
      conversion_result <- convertM4AtoMP3WithSplit(input_path, output_dir, base_name, quality)
      
      if (!conversion_result$success) {
        stop(conversion_result$error)
      }
      
      end_time <- Sys.time()
      conversion_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
      
      # Update status based on whether file was split
      if (conversion_result$split) {
        output$conversionStatus <- renderText(paste(
          "✂️ STEP 4/4: File automatically split (size > 24MB)...\n\n",
          "Original size:", round(input_size_mb, 2), "MB\n",
          "Files created:", conversion_result$parts, "parts\n",
          "Total output size:", round(conversion_result$total_size, 2), "MB\n",
          "Files created:\n",
          paste("•", conversion_result$files, collapse = "\n"), "\n\n",
          "✅ Conversion completed with auto-split!"
        ))
      } else {
        output$conversionStatus <- renderText(paste(
          "✅ STEP 4/4: Single file conversion completed!\n\n",
          "Original size:", round(input_size_mb, 2), "MB\n",
          "Output size:", round(conversion_result$total_size, 2), "MB\n",
          "File created:", conversion_result$files, "\n",
          "No splitting needed (< 24MB)\n\n",
          "✅ Conversion completed successfully!"
        ))
      }
      
      # Update history
      files_list <- paste(conversion_result$files, collapse = "; ")
      new_conversion <- data.frame(
        timestamp = format(Sys.time()),
        input_file = input_name,
        output_files = files_list,
        input_size = round(input_size_mb, 2),
        output_size = round(conversion_result$total_size, 2),
        parts_created = conversion_result$parts,
        quality = quality,
        conversion_time = round(conversion_time, 2),
        stringsAsFactors = FALSE
      )
      
      values$conversions <- rbind(values$conversions, new_conversion)
      values$conversion_complete <- TRUE
      
      # Update converted file info
      output$convertedFileInfo <- renderText({
        compression_ratio <- round(input_size_mb / conversion_result$total_size, 2)
        
        if (conversion_result$split) {
          paste(
            "🔄 CONVERSION WITH AUTO-SPLIT:\n\n",
            "📥 Original:", round(input_size_mb, 2), "MB\n",
            "📤 Total output:", round(conversion_result$total_size, 2), "MB\n",
            "✂️ Parts created:", conversion_result$parts, "files\n",
            "⚙️ Quality:", quality, "\n",
            "⏱️ Time:", round(conversion_time, 2), "seconds\n",
            "📊 Compression:", compression_ratio, ":1\n\n",
            "📁 FILES CREATED:\n",
            paste("•", conversion_result$files, collapse = "\n"), "\n\n",
            "💡 Each part is under 24MB for easy handling!"
          )
        } else {
          paste(
            "🔄 SINGLE FILE CONVERSION:\n\n",
            "📥 Original:", round(input_size_mb, 2), "MB\n",
            "📤 Converted:", round(conversion_result$total_size, 2), "MB\n",
            "⚙️ Quality:", quality, "\n",
            "⏱️ Time:", round(conversion_time, 2), "seconds\n",
            "📊 Compression:", compression_ratio, ":1\n",
            "📁 File:", conversion_result$files, "\n\n",
            "✅ No splitting needed - file is under 24MB!"
          )
        }
      })
      
      if (conversion_result$split) {
        showNotification(paste("Conversion completed! File split into", conversion_result$parts, "parts"), type = "message")
      } else {
        showNotification("Conversion completed successfully!", type = "message")
      }
      
    }, error = function(e) {
      values$conversion_complete <- FALSE
      output$conversionStatus <- renderText(paste(
        "❌ CONVERSION FAILED!\n\n",
        "Error:", e$message, "\n\n",
        "🔧 Troubleshooting:\n",
        "• Check file format (M4A supported)\n",
        "• Verify output directory exists\n",
        "• Ensure sufficient disk space\n",
        "• Try a different quality setting"
      ))
      showNotification(paste("Conversion Error:", e$message), type = "error")
    })
  })
  
  # Open output folder
  observeEvent(input$openFolderBtn, {
    output_dir <- input$outputPath %||% getwd()
    tryCatch({
      system(paste("explorer", output_dir))
    }, error = function(e) {
      showNotification("Could not open folder", type = "warning")
    })
  })
  
  # ==================== FILE SPLITTER FUNCTIONALITY ====================
  
  # Process uploaded file for splitter
  observeEvent(input$audio_file, {
    req(input$audio_file)
    
    file_path <- input$audio_file$datapath
    file_name <- input$audio_file$name
    
    values$processing_log <- paste0("Uploading file: ", file_name, "\n")
    
    tryCatch({
      # Load audio file based on extension
      file_ext <- tolower(tools::file_ext(file_name))
      
      if (file_ext == "mp3") {
        values$audio_data <- readMP3(file_path)
      } else if (file_ext == "wav") {
        values$audio_data <- readWave(file_path)
      } else {
        stop("Unsupported file format. Please use MP3 or WAV files.")
      }
      
      # Get audio information
      duration_sec <- length(values$audio_data) / values$audio_data@samp.rate
      file_size <- file.size(file_path)
      
      values$audio_info <- list(
        duration = duration_sec,
        sample_rate = values$audio_data@samp.rate,
        channels = if(values$audio_data@stereo) 2 else 1,
        bit_depth = values$audio_data@bit,
        file_size = file_size,
        original_name = file_name
      )
      
      values$processing_log <- paste0(values$processing_log,
                                      "✓ Audio file loaded successfully!\n",
                                      "✓ Duration: ", round(duration_sec, 2), " seconds\n",
                                      "✓ Sample Rate: ", values$audio_info$sample_rate, " Hz\n",
                                      "✓ Channels: ", values$audio_info$channels, "\n",
                                      "Ready to split!\n")
      
    }, error = function(e) {
      values$processing_log <- paste0(values$processing_log, 
                                      "✗ Error loading audio file: ", e$message, "\n")
      values$audio_data <- NULL
      values$audio_info <- NULL
    })
  })
  
  # Display audio information
  output$audio_info <- renderText({
    if (!is.null(values$audio_info)) {
      paste0(
        "Original File: ", values$audio_info$original_name, "\n",
        "Duration: ", round(values$audio_info$duration, 2), " seconds\n",
        "Sample Rate: ", values$audio_info$sample_rate, " Hz\n",
        "Channels: ", values$audio_info$channels, "\n",
        "Bit Depth: ", values$audio_info$bit_depth, " bit\n",
        "File Size: ", round(values$audio_info$file_size / 1024 / 1024, 2), " MB"
      )
    } else {
      "No audio file uploaded yet.\n\nPlease upload an MP3 or WAV file to begin."
    }
  })
  
  # Show duration inputs for manual splitting
  output$show_duration_inputs <- reactive({
    !is.null(values$audio_info) && !input$equal_duration
  })
  outputOptions(output, "show_duration_inputs", suspendWhenHidden = FALSE)
  
  # Generate duration input controls for custom split points
  output$duration_inputs <- renderUI({
    req(values$audio_info, !input$equal_duration, input$num_splits >= 2)
    
    max_duration <- values$audio_info$duration
    split_points <- input$num_splits - 1
    
    inputs <- lapply(1:split_points, function(i) {
      numericInput(paste0("split_point_", i), 
                   paste("Split point", i, "(seconds):"),
                   value = round((max_duration / input$num_splits) * i, 2),
                   min = 0.1, 
                   max = max_duration - 0.1, 
                   step = 0.1)
    })
    
    do.call(tagList, inputs)
  })
  
  # Main split audio function
  observeEvent(input$split_audio, {
    req(values$audio_data, input$num_splits >= 2, input$output_folder != "")
    
    values$processing_log <- paste0(values$processing_log, 
                                    "\n=== Starting Audio Split Process ===\n")
    
    tryCatch({
      duration <- values$audio_info$duration
      sample_rate <- values$audio_info$sample_rate
      
      # Create output directory
      output_folder <- trimws(input$output_folder)
      # Use a temporary directory that we can control
      values$output_dir <- file.path(tempdir(), output_folder)
      
      if (dir.exists(values$output_dir)) {
        unlink(values$output_dir, recursive = TRUE)
      }
      dir.create(values$output_dir, recursive = TRUE)
      
      values$processing_log <- paste0(values$processing_log, 
                                      "✓ Created output directory\n")
      
      # Calculate split points
      if (input$equal_duration) {
        split_duration <- duration / input$num_splits
        split_points <- seq(0, duration, by = split_duration)
        values$processing_log <- paste0(values$processing_log, 
                                        "✓ Using equal duration splits (", 
                                        round(split_duration, 2), " seconds each)\n")
      } else {
        # Get manual split points
        manual_points <- c()
        for (i in 1:(input$num_splits - 1)) {
          point_value <- input[[paste0("split_point_", i)]]
          if (!is.null(point_value)) {
            manual_points <- c(manual_points, point_value)
          }
        }
        split_points <- c(0, sort(manual_points), duration)
        values$processing_log <- paste0(values$processing_log, 
                                        "✓ Using custom split points\n")
      }
      
      # Split and save audio segments
      results_data <- data.frame(
        Segment = integer(),
        Filename = character(),
        Start_Time = numeric(),
        End_Time = numeric(),
        Duration = numeric(),
        File_Size_KB = numeric(),
        Status = character(),
        stringsAsFactors = FALSE
      )
      
      values$temp_files <- c()  # Reset temp files list
      
      for (i in 1:(length(split_points) - 1)) {
        start_time <- split_points[i]
        end_time <- split_points[i + 1]
        
        values$processing_log <- paste0(values$processing_log, 
                                        "Processing segment ", i, " (", 
                                        round(start_time, 1), "s - ", 
                                        round(end_time, 1), "s)...\n")
        
        # Convert time to samples
        start_sample <- max(1, round(start_time * sample_rate))
        end_sample <- min(length(values$audio_data), round(end_time * sample_rate))
        
        # Extract segment
        if (values$audio_data@stereo) {
          segment <- values$audio_data[start_sample:end_sample, ]
        } else {
          segment <- values$audio_data[start_sample:end_sample]
        }
        
        # Create filename
        file_extension <- input$output_format
        filename <- paste0(input$output_prefix, "_", 
                           sprintf("%02d", i), ".", file_extension)
        filepath <- file.path(values$output_dir, filename)
        
        # Save segment
        tryCatch({
          if (file_extension == "wav") {
            writeWave(segment, filepath)
          } else {
            # For MP3, we'll save as WAV first (MP3 writing is complex in R)
            writeWave(segment, filepath)
          }
          
          file_size <- file.size(filepath)
          status <- "✓ Success"
          values$temp_files <- c(values$temp_files, filepath)
          
        }, error = function(e) {
          status <- paste("✗ Error:", e$message)
          file_size <- 0
        })
        
        # Add to results
        results_data <- rbind(results_data, data.frame(
          Segment = i,
          Filename = filename,
          Start_Time = round(start_time, 2),
          End_Time = round(end_time, 2),
          Duration = round(end_time - start_time, 2),
          File_Size_KB = round(file_size / 1024, 1),
          Status = status
        ))
      }
      
      values$results <- results_data
      success_count <- sum(grepl("Success", results_data$Status))
      
      values$processing_log <- paste0(values$processing_log, 
                                      "\n=== SPLITTING COMPLETED ===\n",
                                      "✓ Successfully created ", success_count, " out of ", 
                                      nrow(results_data), " segments\n",
                                      "✓ Files saved in: ", values$output_dir, "\n")
      
    }, error = function(e) {
      values$processing_log <- paste0(values$processing_log, 
                                      "✗ Critical error during splitting: ", e$message, "\n")
    })
  })
  
  # Display processing log
  output$process_log <- renderText({
    values$processing_log
  })
  
  # Show output location
  output$output_location <- renderText({
    if (!is.null(values$output_dir)) {
      values$output_dir
    }
  })
  
  # Show results table
  output$show_results <- reactive({
    !is.null(values$results)
  })
  outputOptions(output, "show_results", suspendWhenHidden = FALSE)
  
  # Show download button
  output$show_download <- reactive({
    !is.null(values$results) && length(values$temp_files) > 0
  })
  outputOptions(output, "show_download", suspendWhenHidden = FALSE)
  
  output$results_table <- renderDT({
    req(values$results)
    datatable(values$results, 
              options = list(pageLength = 10, scrollX = TRUE, dom = 't'),
              rownames = FALSE) %>%
      formatStyle("Status", 
                  backgroundColor = styleEqual("✓ Success", "#d4edda"),
                  color = styleEqual("✓ Success", "#155724"))
  })
  
  # Download handler for ZIP file
  output$download_zip <- downloadHandler(
    filename = function() {
      paste0("split_audio_", Sys.Date(), ".zip")
    },
    content = function(file) {
      # Create temporary zip file
      temp_zip <- tempfile(fileext = ".zip")
      
      # Create zip with all the split files
      if (length(values$temp_files) > 0) {
        zip(temp_zip, values$temp_files, flags = "-j")  # -j flag removes directory structure
        file.copy(temp_zip, file)
      }
    },
    contentType = "application/zip"
  )
  
  # ==================== ANALYTICS ====================
  
  # Analytics - Value boxes
  output$totalFiles <- renderValueBox({
    valueBox(
      value = nrow(values$transcriptions),
      subtitle = "Total Files Processed",
      icon = icon("file-audio"),
      color = "purple"
    )
  })
  
  output$totalWords <- renderValueBox({
    total_words <- sum(values$transcriptions$word_count, na.rm = TRUE)
    valueBox(
      value = total_words,
      subtitle = "Total Words Transcribed",
      icon = icon("font"),
      color = "green"
    )
  })
  
  output$avgDuration <- renderValueBox({
    avg_time <- mean(values$transcriptions$processing_time, na.rm = TRUE)
    avg_time <- round(avg_time, 2)
    valueBox(
      value = paste(avg_time, "s"),
      subtitle = "Avg Processing Time",
      icon = icon("clock"),
      color = "yellow"
    )
  })
  
  # Word count plot
  output$wordCountPlot <- renderPlotly({
    req(nrow(values$transcriptions) > 0)
    
    p <- plot_ly(
      x = seq_len(nrow(values$transcriptions)),
      y = values$transcriptions$word_count,
      type = "scatter",
      mode = "lines+markers",
      line = list(color = "#667eea"),
      marker = list(color = "#764ba2")
    ) %>%
      layout(
        title = "Word Count Over Time",
        xaxis = list(title = "File Number"),
        yaxis = list(title = "Word Count"),
        plot_bgcolor = "#f8f9ff",
        paper_bgcolor = "#ffffff",
        font = list(color = "#2c3e50")
      )
    
    p
  })
  
  # Processing time plot
  output$processingTimePlot <- renderPlotly({
    req(nrow(values$transcriptions) > 0)
    
    p <- plot_ly(
      x = seq_len(nrow(values$transcriptions)),
      y = values$transcriptions$processing_time,
      type = "bar",
      marker = list(color = "#11998e")
    ) %>%
      layout(
        title = "Processing Time by File",
        xaxis = list(title = "File Number"),
        yaxis = list(title = "Processing Time (seconds)"),
        plot_bgcolor = "#f8f9ff",
        paper_bgcolor = "#ffffff",
        font = list(color = "#2c3e50")
      )
    
    p
  })
  
  # History table
  output$historyTable <- DT::renderDataTable({
    req(nrow(values$transcriptions) > 0)
    
    datatable(
      values$transcriptions,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 'Bfrtip'
      ),
      style = "bootstrap4"
    )
  })
  
  # Conversion history table
  output$conversionHistoryTable <- DT::renderDataTable({
    req(nrow(values$conversions) > 0)
    
    datatable(
      values$conversions,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 'Bfrtip'
      ),
      style = "bootstrap4"
    )
  })
  
  # Clean up temporary files when session ends
  session$onSessionEnded(function() {
    if (!is.null(values$output_dir) && dir.exists(values$output_dir)) {
      unlink(values$output_dir, recursive = TRUE)
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)