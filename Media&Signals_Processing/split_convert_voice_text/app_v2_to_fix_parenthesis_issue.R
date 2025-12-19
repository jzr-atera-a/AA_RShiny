# Audio Speech-to-Text R Shiny Dashboard with File Splitter and Bulk Text Analysis
# FINAL CORRECTED VERSION - All fixes applied

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
        .file-count-badge {
          background: #667eea;
          color: white;
          padding: 5px 15px;
          border-radius: 20px;
          font-weight: bold;
          display: inline-block;
          margin: 10px 0;
        }
        .timeout-warning {
          background: #fff3cd;
          border-left: 5px solid #ffc107;
          padding: 10px 15px;
          border-radius: 8px;
          margin: 10px 0;
          color: #856404;
        }
      "))
    ),
    
    sidebarMenu(
      menuItem("Audio Converter", tabName = "converter", icon = icon("exchange-alt")),
      menuItem("File Splitter", tabName = "splitter", icon = icon("scissors")),
      menuItem("Settings", tabName = "settings", icon = icon("cog")),
      menuItem("Audio Transcription", tabName = "transcription", icon = icon("microphone")),
      menuItem("Bulk Text Analysis", tabName = "bulk_analysis", icon = icon("folder-open")),
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
                               value = "",
                               placeholder = "Select output directory...")
              ),
              column(4,
                     br(),
                     shinyDirButton("browseOutputDir", 
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
                     numericInput("converter_max_size_mb", 
                                  "Max file size (MB):",
                                  value = 24,
                                  min = 1,
                                  max = 500,
                                  step = 1)
              )
            ),
            
            fluidRow(
              column(12,
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
                actionButton("openConverterFolderBtn", 
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
              column(6,
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
              
              column(6,
                     h4("Step 2: Select Output Directory"),
                     fluidRow(
                       column(8,
                              textInput("splitter_output_path", 
                                        "Output directory:",
                                        value = "",
                                        placeholder = "Select output directory...")
                       ),
                       column(4,
                              br(),
                              shinyDirButton("browseSplitterDir", 
                                             "Browse...", 
                                             title = "Select Output Directory",
                                             class = "btn-default",
                                             icon = icon("folder"),
                                             style = "width: 100%;")
                       )
                     ),
                     
                     textInput("output_folder", "Output folder name:",
                               value = "split_audio_files",
                               placeholder = "Enter folder name"),
                     
                     helpText("Files will be saved in a subfolder with this name in the selected directory.")
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
            
            radioButtons("split_method", "Split Method:",
                         choices = list(
                           "By Number of Files" = "num_files",
                           "By File Size" = "file_size"
                         ),
                         selected = "num_files"),
            
            conditionalPanel(
              condition = "input.split_method == 'num_files'",
              numericInput("num_splits", "Number of files to split into:", 
                           value = 2, min = 2, max = 50, step = 1),
              
              checkboxInput("equal_duration", "Split into equal duration segments", 
                            value = TRUE),
              
              conditionalPanel(
                condition = "input.equal_duration == false",
                helpText("Custom split points will be available after uploading the file")
              )
            ),
            
            conditionalPanel(
              condition = "input.split_method == 'file_size'",
              numericInput("splitter_max_size_mb", 
                           "Maximum file size (MB):", 
                           value = 24, 
                           min = 1, 
                           max = 500, 
                           step = 1),
              helpText("Audio will be split into multiple files, each not exceeding this size.")
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
                             icon = icon("download")),
              br(), br(),
              actionButton("openSplitterFolderBtn", 
                           "Open Output Folder", 
                           class = "btn-success",
                           icon = icon("folder-open"))
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
              tags$li("Bulk text analysis and summarization"),
              tags$li("Transcription history and analytics"),
              tags$li("Custom save locations"),
              tags$li("Processing time tracking"),
              tags$li("Configurable request timeout")
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
            height = 550,
            
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
            
            h5("Transcription Settings:"),
            numericInput("apiTimeout", 
                         "Request Timeout (seconds):",
                         value = 180,
                         min = 30,
                         max = 600,
                         step = 30),
            
            br(),
            
            actionButton("transcribeBtn", 
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
            height = 550,
            
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
                          height = "300px",
                          resize = "vertical"),
            
            h5("Save Transcription:"),
            fluidRow(
              column(6,
                     textInput("transcription_output_path", 
                               "Save directory:", 
                               placeholder = "Select output directory...")
              ),
              column(3,
                     br(),
                     shinyDirButton("browseTranscriptionDir", 
                                    "Browse...", 
                                    title = "Select Output Directory",
                                    class = "btn-default",
                                    icon = icon("folder"),
                                    style = "width: 100%;")
              ),
              column(3,
                     br(),
                     actionButton("saveBtn", 
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
      ),
      
      # Bulk Text Analysis Tab
      tabItem(
        tabName = "bulk_analysis",
        fluidRow(
          box(
            title = "Step 1: Select Folder with Text Files", 
            status = "primary", 
            solidHeader = TRUE,
            width = 6,
            
            fluidRow(
              column(8,
                     textInput("bulk_folder_path", 
                               "Folder containing .txt files:",
                               value = "",
                               placeholder = "Select folder with text files...")
              ),
              column(4,
                     br(),
                     shinyDirButton("browseBulkFolder", 
                                    "Browse...", 
                                    title = "Select Folder",
                                    class = "btn-default",
                                    icon = icon("folder"),
                                    style = "width: 100%;")
              )
            ),
            
            br(),
            
            actionButton("scanFolderBtn", 
                         "Scan Folder", 
                         class = "btn-info",
                         icon = icon("search"),
                         style = "width: 100%;"),
            
            br(), br(),
            
            conditionalPanel(
              condition = "output.folderScanned",
              div(
                class = "reference-box",
                h5(icon("folder-open"), " Folder Contents:"),
                uiOutput("folderContentsDisplay")
              )
            )
          ),
          
          box(
            title = "Step 2: Configure Analysis Settings", 
            status = "warning", 
            solidHeader = TRUE,
            width = 6,
            
            selectInput("sortMethod", 
                        "Sort files by:",
                        choices = c(
                          "Filename (alphabetically)" = "name",
                          "Creation time (oldest first)" = "ctime",
                          "Modification time (newest first)" = "mtime"
                        ),
                        selected = "name"),
            
            numericInput("maxSummaryWords", 
                         "Maximum summary length (words):",
                         value = 500,
                         min = 50,
                         max = 5000,
                         step = 50),
            
            numericInput("bulkAnalysisTimeout", 
                         "Request Timeout (seconds):",
                         value = 180,
                         min = 30,
                         max = 600,
                         step = 30),
            
            textInput("analysisPrompt",
                      "Custom prompt (optional):",
                      value = "Summarize the following combined text:",
                      placeholder = "Enter custom prompt..."),
            
            helpText("The app will concatenate all .txt files in the selected folder and send them to ChatGPT for analysis."),
            
            br(),
            
            h5("Save Concatenated Text:"),
            fluidRow(
              column(8,
                     textInput("concat_output_path", 
                               "Output directory:", 
                               placeholder = "Select directory for concatenated file...")
              ),
              column(4,
                     br(),
                     shinyDirButton("browseConcatDir", 
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
                     actionButton("downloadConcatBtn", 
                                  "Download Concatenated Text", 
                                  class = "btn-info btn-lg",
                                  icon = icon("download"),
                                  style = "width: 100%;")
              ),
              column(6,
                     actionButton("analyzeBtn", 
                                  "Analyze & Summarize", 
                                  class = "btn-success btn-lg",
                                  icon = icon("brain"),
                                  style = "width: 100%;")
                  )
                )
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
            
            verbatimTextOutput("analysisStatus"),
            
            conditionalPanel(
              condition = "$('html').hasClass('shiny-busy')",
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
            
            textAreaInput("analysisSummary", 
                          label = NULL,
                          value = "",
                          placeholder = "Analysis summary will appear here...",
                          height = "400px",
                          resize = "vertical"),
            
            br(),
            
            fluidRow(
              column(6,
                     textInput("summary_output_path", 
                               "Save directory:", 
                               placeholder = "Select output directory...")
              ),
              column(3,
                     br(),
                     shinyDirButton("browseSummaryDir", 
                                    "Browse...", 
                                    title = "Select Output Directory",
                                    class = "btn-default",
                                    icon = icon("folder"),
                                    style = "width: 100%;")
              ),
              column(3,
                     br(),
                     actionButton("saveSummaryBtn", 
                                  "Save Summary", 
                                  class = "btn-success",
                                  icon = icon("save"),
                                  style = "width: 100%;")
              )
            ),
            br(),
            textInput("summary_filename", 
                      "Filename (without extension):", 
                      value = paste0("summary_", format(Sys.time(), "%Y%m%d_%H%M%S")),
                      placeholder = "Enter filename...")
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
  
  # Increase file upload limit to 100MB
  options(shiny.maxRequestSize = 100*1024^2)
  
  # Set up volumes for directory browsing
  volumes <- c(Home = fs::path_home(), getVolumes()())
  if (.Platform$OS.type == "windows") {
    drive_letters <- LETTERS[3:26]
    for (letter in drive_letters) {
      drive_path <- paste0(letter, ":/")
      if (dir.exists(drive_path)) {
        volumes[[paste0(letter, ":")]] <- drive_path
      }
    }
  }
  
  # Initialize shinyDirChoose for all directory browsers
  shinyDirChoose(input, "browseOutputDir", roots = volumes, session = session)
  shinyDirChoose(input, "browseSplitterDir", roots = volumes, session = session)
  shinyDirChoose(input, "browseTranscriptionDir", roots = volumes, session = session)
  shinyDirChoose(input, "browseBulkFolder", roots = volumes, session = session)
  shinyDirChoose(input, "browseSummaryDir", roots = volumes, session = session)
  shinyDirChoose(input, "browseConcatDir", roots = volumes, session = session)
  
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
    audio_data = NULL,
    audio_info = NULL,
    processing_log = "Ready to process audio files...\n",
    results = NULL,
    output_dir = NULL,
    temp_files = c(),
    converter_output_dir = getwd(),
    splitter_output_dir = getwd(),
    transcription_output_dir = getwd(),
    bulk_folder_dir = NULL,
    summary_output_dir = getwd(),
    concat_output_dir = getwd(),
    scanned_files = NULL,
    current_summary = "",
    folder_scanned = FALSE,
    concatenated_text = NULL
  )
  
  # Observer for Converter output directory selection
  observeEvent(input$browseOutputDir, {
    if (!is.null(input$browseOutputDir) && !is.integer(input$browseOutputDir)) {
      selected_path <- parseDirPath(volumes, input$browseOutputDir)
      if (length(selected_path) > 0) {
        values$converter_output_dir <- selected_path
        updateTextInput(session, "outputPath", value = selected_path)
        showNotification("Converter output directory selected", type = "message")
      }
    }
  })
  
  # Observer for Splitter output directory selection
  observeEvent(input$browseSplitterDir, {
    if (!is.null(input$browseSplitterDir) && !is.integer(input$browseSplitterDir)) {
      selected_path <- parseDirPath(volumes, input$browseSplitterDir)
      if (length(selected_path) > 0) {
        values$splitter_output_dir <- selected_path
        updateTextInput(session, "splitter_output_path", value = selected_path)
        showNotification("Splitter output directory selected", type = "message")
      }
    }
  })
  
  # Observer for Transcription output directory selection
  observeEvent(input$browseTranscriptionDir, {
    if (!is.null(input$browseTranscriptionDir) && !is.integer(input$browseTranscriptionDir)) {
      selected_path <- parseDirPath(volumes, input$browseTranscriptionDir)
      if (length(selected_path) > 0) {
        values$transcription_output_dir <- selected_path
        updateTextInput(session, "transcription_output_path", value = selected_path)
        showNotification("Transcription save directory selected", type = "message")
      }
    }
  })
  
  # Observer for Bulk Analysis folder selection
  observeEvent(input$browseBulkFolder, {
    if (!is.null(input$browseBulkFolder) && !is.integer(input$browseBulkFolder)) {
      selected_path <- parseDirPath(volumes, input$browseBulkFolder)
      if (length(selected_path) > 0) {
        values$bulk_folder_dir <- selected_path
        updateTextInput(session, "bulk_folder_path", value = selected_path)
        showNotification("Bulk analysis folder selected", type = "message")
      }
    }
  })
  
  # Observer for Summary output directory selection
  observeEvent(input$browseSummaryDir, {
    if (!is.null(input$browseSummaryDir) && !is.integer(input$browseSummaryDir)) {
      selected_path <- parseDirPath(volumes, input$browseSummaryDir)
      if (length(selected_path) > 0) {
        values$summary_output_dir <- selected_path
        updateTextInput(session, "summary_output_path", value = selected_path)
        showNotification("Summary save directory selected", type = "message")
      }
    }
  })
  
  # Observer for Concatenated text output directory selection
  observeEvent(input$browseConcatDir, {
    if (!is.null(input$browseConcatDir) && !is.integer(input$browseConcatDir)) {
      selected_path <- parseDirPath(volumes, input$browseConcatDir)
      if (length(selected_path) > 0) {
        values$concat_output_dir <- selected_path
        updateTextInput(session, "concat_output_path", value = selected_path)
        showNotification("Concatenated text output directory selected", type = "message")
      }
    }
  })
  
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
  
  # Folder scanned status
  output$folderScanned <- reactive({
    return(values$folder_scanned)
  })
  outputOptions(output, 'folderScanned', suspendWhenHidden = FALSE)
  
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
      url <- "https://api.openai.com/v1/models"
      
      response <- GET(
        url,
        add_headers(Authorization = paste("Bearer", api_key)),
        timeout(10)
      )
      
      status <- status_code(response)
      result <- list()
      
      if (status == 200) {
        content_result <- content(response, "parsed")
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
        result$message <- "✗ Authentication Failed\nInvalid API key."
        result$status <- "error"
        
      } else if (status == 429) {
        result$success <- FALSE
        result$message <- "✗ Rate Limit Exceeded"
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
  
  # FIXED: Transcription function with proper timeout configuration
  transcribeAudio <- function(file_path, api_key, timeout_seconds) {
    req(api_key, file_path)
    
    api_key <- trimws(api_key)
    if (nchar(api_key) == 0) {
      stop("API key is required.")
    }
    
    if (!file.exists(file_path)) {
      stop("Audio file not found.")
    }
    
    url <- "https://api.openai.com/v1/audio/transcriptions"
    
    body <- list(
      file = upload_file(file_path),
      model = input$model %||% "whisper-1"
    )
    
    language <- input$language %||% ""
    if (nchar(language) > 0) {
      body$language <- language
    }
    
    # CORRECTED: Proper timeout implementation using httr's timeout function
    response <- POST(
      url,
      add_headers(Authorization = paste("Bearer", api_key)),
      body = body,
      encode = "multipart",
      httr::timeout(timeout_seconds)  # FIXED: Using httr::timeout() correctly
    )
    
    status <- status_code(response)
    
    if (status != 200) {
      error_content <- content(response, "text", encoding = "UTF-8")
      if (status == 401) {
        stop("Authentication failed.")
      } else if (status == 413) {
        stop("File too large.")
      } else {
        stop(paste("API Error:", error_content))
      }
    }
    
    content_result <- content(response, "parsed", encoding = "UTF-8")
    transcription_text <- content_result$text
    
    if (is.null(transcription_text) || length(transcription_text) == 0) {
      return("No speech detected.")
    }
    
    return(transcription_text)
  }
  
  # FIXED: ChatGPT text analysis function with proper timeout
  analyzeBulkText <- function(combined_text, api_key, max_words, custom_prompt, timeout_seconds) {
    req(api_key, combined_text)
    
    api_key <- trimws(api_key)
    if (nchar(api_key) == 0) {
      stop("API key is required.")
    }
    
    url <- "https://api.openai.com/v1/chat/completions"
    
    system_message <- paste0(
      "You are a helpful assistant that summarizes and analyzes text. ",
      "Provide a comprehensive summary limited to approximately ", max_words, " words."
    )
    
    user_message <- paste0(
      custom_prompt, "\n\n",
      "Text to analyze:\n\n",
      combined_text
    )
    
    body <- list(
      model = "gpt-4o-mini",
      messages = list(
        list(role = "system", content = system_message),
        list(role = "user", content = user_message)
      ),
      max_tokens = max_words * 2,
      temperature = 0.7
    )
    
    # CORRECTED: Proper timeout implementation using httr's timeout function
    response <- POST(
      url,
      add_headers(
        Authorization = paste("Bearer", api_key),
        `Content-Type` = "application/json"
      ),
      body = toJSON(body, auto_unbox = TRUE),
      encode = "raw",
      httr::timeout(timeout_seconds)  # FIXED: Using httr::timeout() correctly
    )
    
    status <- status_code(response)
    
    if (status != 200) {
      error_content <- content(response, "text", encoding = "UTF-8")
      if (status == 401) {
        stop("Authentication failed. Check your API key.")
      } else if (status == 429) {
        stop("Rate limit exceeded. Please wait and try again.")
      } else {
        stop(paste("API Error (Status", status, "):", error_content))
      }
    }
    
    content_result <- content(response, "parsed", encoding = "UTF-8")
    
    if (is.null(content_result$choices) || length(content_result$choices) == 0) {
      stop("No response from ChatGPT")
    }
    
    summary_text <- content_result$choices[[1]]$message$content
    
    return(summary_text)
  }
  
  # Scan folder for text files
  observeEvent(input$scanFolderBtn, {
    req(values$bulk_folder_dir)
    
    folder_path <- values$bulk_folder_dir
    
    if (!dir.exists(folder_path)) {
      showNotification("Selected folder does not exist", type = "error")
      return()
    }
    
    tryCatch({
      # Find all .txt files in the folder
      txt_files <- list.files(folder_path, pattern = "\\.txt$", full.names = TRUE, ignore.case = TRUE)
      
      if (length(txt_files) == 0) {
        showNotification("No .txt files found in the selected folder", type = "warning")
        values$folder_scanned <- FALSE
        values$scanned_files <- NULL
        return()
      }
      
      # Get file information
      file_info <- data.frame(
        filename = basename(txt_files),
        path = txt_files,
        size = file.size(txt_files),
        ctime = file.info(txt_files)$ctime,
        mtime = file.info(txt_files)$mtime,
        stringsAsFactors = FALSE
      )
      
      values$scanned_files <- file_info
      values$folder_scanned <- TRUE
      
      showNotification(paste("Found", nrow(file_info), "text file(s)"), type = "message")
      
    }, error = function(e) {
      showNotification(paste("Error scanning folder:", e$message), type = "error")
      values$folder_scanned <- FALSE
    })
  })
  
  # Display folder contents
  output$folderContentsDisplay <- renderUI({
    req(values$scanned_files)
    
    file_count <- nrow(values$scanned_files)
    total_size_kb <- sum(values$scanned_files$size) / 1024
    
    tagList(
      div(class = "file-count-badge",
          paste(file_count, "text file(s) found")
      ),
      p(paste("Total size:", round(total_size_kb, 2), "KB")),
      tags$ul(
        lapply(1:min(10, file_count), function(i) {
          tags$li(
            values$scanned_files$filename[i],
            tags$small(paste0(" (", round(values$scanned_files$size[i] / 1024, 1), " KB)"))
          )
        })
      ),
      if (file_count > 10) {
        p(paste("... and", file_count - 10, "more file(s)"))
      }
    )
  })
  
  # Analyze button event - uses BULK ANALYSIS timeout
  observeEvent(input$analyzeBtn, {
    req(values$scanned_files)
    
    if (is.null(values$api_key) || nchar(trimws(values$api_key)) == 0) {
      output$analysisStatus <- renderText("❌ Error: No API key found.")
      showNotification("Please set your API key in Settings first.", type = "error")
      return()
    }
    
    # Use the BULK ANALYSIS timeout value (NOT transcription timeout)
    timeout_value <- input$bulkAnalysisTimeout %||% 180
    
    output$analysisStatus <- renderText(paste0(
      "🔄 Initializing analysis...\n",
      "⏱️ Timeout set to: ", timeout_value, " seconds\n"
    ))
    
    tryCatch({
      start_time <- Sys.time()
      
      # Sort files according to user preference
      sorted_files <- values$scanned_files
      
      if (input$sortMethod == "name") {
        sorted_files <- sorted_files[order(sorted_files$filename), ]
        output$analysisStatus <- renderText("📁 Sorting files by name...\n")
      } else if (input$sortMethod == "ctime") {
        sorted_files <- sorted_files[order(sorted_files$ctime), ]
        output$analysisStatus <- renderText("📁 Sorting files by creation time...\n")
      } else if (input$sortMethod == "mtime") {
        sorted_files <- sorted_files[order(sorted_files$mtime, decreasing = TRUE), ]
        output$analysisStatus <- renderText("📁 Sorting files by modification time...\n")
      }
      
      # Read and concatenate all text files
      output$analysisStatus <- renderText("📖 Reading text files...\n")
      
      all_text <- character()
      for (i in 1:nrow(sorted_files)) {
        file_content <- readLines(sorted_files$path[i], warn = FALSE, encoding = "UTF-8")
        file_text <- paste(file_content, collapse = "\n")
        
        # Add file header
        all_text <- c(all_text, 
                      paste0("\n=== FILE: ", sorted_files$filename[i], " ===\n"),
                      file_text)
      }
      
      combined_text <- paste(all_text, collapse = "\n")
      word_count <- length(strsplit(combined_text, "\\s+")[[1]])
      
      output$analysisStatus <- renderText(paste0(
        "✓ Read ", nrow(sorted_files), " file(s)\n",
        "✓ Total words: ", word_count, "\n",
        "⏱️ Using timeout: ", timeout_value, " seconds\n",
        "🤖 Sending to ChatGPT for analysis...\n"
      ))
      
      Sys.sleep(1)
      
      # Send to ChatGPT for analysis with BULK ANALYSIS timeout
      summary <- analyzeBulkText(
        combined_text, 
        values$api_key, 
        input$maxSummaryWords,
        input$analysisPrompt,
        timeout_value  # Using BULK ANALYSIS timeout
      )
      
      end_time <- Sys.time()
      total_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
      
      updateTextAreaInput(session, "analysisSummary", value = summary)
      values$current_summary <- summary
      
      summary_word_count <- length(strsplit(summary, "\\s+")[[1]])
      
      output$analysisStatus <- renderText(paste0(
        "✅ Analysis completed!\n\n",
        "Files analyzed: ", nrow(sorted_files), "\n",
        "Input words: ", word_count, "\n",
        "Summary words: ", summary_word_count, "\n",
        "Processing time: ", round(total_time, 2), " seconds"
      ))
      
      showNotification("Analysis completed successfully!", type = "message")
      
    }, error = function(e) {
      output$analysisStatus <- renderText(paste("❌ Error:", e$message))
      showNotification(paste("Analysis failed:", e$message), type = "error")
    })
  })
  
  # Download concatenated text button event
  observeEvent(input$downloadConcatBtn, {
    req(values$scanned_files)
    
    output_dir <- values$concat_output_dir
    
    if (is.null(output_dir) || !dir.exists(output_dir)) {
      showNotification("Please select an output directory for the concatenated file.", type = "error")
      return()
    }
    
    tryCatch({
      showNotification("Preparing concatenated text...", type = "message")
      
      # Sort files according to user preference
      sorted_files <- values$scanned_files
      
      if (input$sortMethod == "name") {
        sorted_files <- sorted_files[order(sorted_files$filename), ]
      } else if (input$sortMethod == "ctime") {
        sorted_files <- sorted_files[order(sorted_files$ctime), ]
      } else if (input$sortMethod == "mtime") {
        sorted_files <- sorted_files[order(sorted_files$mtime, decreasing = TRUE), ]
      }
      
      # Read and concatenate all text files
      all_text <- character()
      for (i in 1:nrow(sorted_files)) {
        file_content <- readLines(sorted_files$path[i], warn = FALSE, encoding = "UTF-8")
        file_text <- paste(file_content, collapse = "\n")
        
        # Add file header
        all_text <- c(all_text, 
                      paste0("\n=== FILE: ", sorted_files$filename[i], " ===\n"),
                      file_text)
      }
      
      combined_text <- paste(all_text, collapse = "\n")
      values$concatenated_text <- combined_text
      
      # Generate filename
      timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
      filename <- paste0("concatenated_text_", timestamp, ".txt")
      save_path <- file.path(output_dir, filename)
      
      # Save the concatenated text
      writeLines(combined_text, save_path)
      
      word_count <- length(strsplit(combined_text, "\\s+")[[1]])
      
      showNotification(
        paste0("Concatenated text saved!\n",
               "Files: ", nrow(sorted_files), "\n",
               "Words: ", word_count, "\n",
               "Location: ", save_path), 
        type = "message",
        duration = 10
      )
      
    }, error = function(e) {
      showNotification(paste("Error creating concatenated text:", e$message), type = "error")
    })
  })
  
  # Save summary
  observeEvent(input$saveSummaryBtn, {
    req(values$current_summary)
    
    output_dir <- values$summary_output_dir
    
    if (is.null(output_dir) || !dir.exists(output_dir)) {
      showNotification("Please select a valid output directory", type = "error")
      return()
    }
    
    filename <- input$summary_filename
    if (is.null(filename) || nchar(trimws(filename)) == 0) {
      filename <- paste0("summary_", format(Sys.time(), "%Y%m%d_%H%M%S"))
    }
    
    if (!grepl("\\.txt$", filename, ignore.case = TRUE)) {
      filename <- paste0(filename, ".txt")
    }
    
    save_path <- file.path(output_dir, filename)
    
    tryCatch({
      writeLines(values$current_summary, save_path)
      showNotification(paste("Summary saved to:", save_path), type = "message")
      
    }, error = function(e) {
      showNotification(paste("Error saving file:", e$message), type = "error")
    })
  })
  
  # Transcribe button event - uses TRANSCRIPTION timeout
  observeEvent(input$transcribeBtn, {
    req(input$audioFile)
    
    if (is.null(values$api_key) || nchar(trimws(values$api_key)) == 0) {
      output$statusOutput <- renderText("❌ Error: No API key found.")
      showNotification("Please set your API key in Settings first.", type = "error")
      return()
    }
    
    file_size_mb <- round(input$audioFile$size / 1024 / 1024, 2)
    file_name <- input$audioFile$name
    timeout_value <- input$apiTimeout %||% 180
    
    output$statusOutput <- renderText(paste(
      "🔄 Initializing transcription...\n\n",
      "File:", file_name, "\n",
      "Size:", file_size_mb, "MB\n",
      "Timeout:", timeout_value, "seconds"
    ))
    
    Sys.sleep(1)
    
    tryCatch({
      start_time <- Sys.time()
      
      output$statusOutput <- renderText(paste0(
        "📤 Uploading to OpenAI...\n",
        "⏳ Maximum wait time: ", timeout_value, " seconds..."
      ))
      
      # Pass user-specified timeout to transcription function
      transcription <- transcribeAudio(input$audioFile$datapath, values$api_key, timeout_value)
      
      end_time <- Sys.time()
      total_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
      
      updateTextAreaInput(session, "transcriptionText", value = transcription)
      values$current_transcription <- transcription
      
      word_count <- length(strsplit(trimws(transcription), "\\s+")[[1]])
      
      new_row <- data.frame(
        timestamp = as.character(Sys.time()),
        filename = file_name,
        word_count = word_count,
        processing_time = round(total_time, 2),
        file_size = file_size_mb,
        stringsAsFactors = FALSE
      )
      
      values$transcriptions <- rbind(values$transcriptions, new_row)
      
      output$statusOutput <- renderText(paste(
        "✅ Transcription completed!\n\n",
        "Words:", word_count, "\n",
        "Time:", round(total_time, 2), "seconds"
      ))
      
      showNotification("Transcription completed!", type = "message")
      
    }, error = function(e) {
      output$statusOutput <- renderText(paste("❌ Error:", e$message))
      showNotification(paste("Transcription failed:", e$message), type = "error")
    })
  })
  
  # FIXED: Save transcription with auto-generated filename from audio file
  observeEvent(input$saveBtn, {
    req(values$current_transcription)
    req(input$audioFile)
    
    output_dir <- values$transcription_output_dir
    
    if (is.null(output_dir) || !dir.exists(output_dir)) {
      showNotification("Please select a valid output directory", type = "error")
      return()
    }
    
    # Use the original audio filename without extension, append .txt
    audio_filename <- input$audioFile$name
    filename <- paste0(tools::file_path_sans_ext(audio_filename), ".txt")
    
    save_path <- file.path(output_dir, filename)
    
    tryCatch({
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
    values$connection_tested <- FALSE
    showNotification("Settings saved successfully!", type = "message")
  })
  
  # Test API Connection
  observeEvent(input$testConnection, {
    api_key_to_test <- input$apiKey %||% values$api_key
    req(api_key_to_test)
    
    showNotification("Testing API connection...", type = "message")
    result <- testOpenAIConnection(api_key_to_test)
    
    values$connection_tested <- TRUE
    values$api_status <- result$message
    
    output$apiConnectionStatus <- renderText({
      result$message
    })
    
    if (result$success) {
      showNotification("API connection successful!", type = "message")
      values$api_key <- api_key_to_test
    } else {
      showNotification("API connection failed.", type = "error")
    }
  })
  
  # Audio conversion function with auto-splitting
  convertM4AtoMP3WithSplit <- function(input_path, output_dir, base_filename, quality = "192k", max_size_mb = 24) {
    tryCatch({
      temp_output <- file.path(output_dir, paste0(base_filename, "_temp.mp3"))
      av::av_audio_convert(input_path, temp_output, format = "mp3")
      
      file_size_mb <- file.info(temp_output)$size / (1024^2)
      
      if (file_size_mb <= max_size_mb) {
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
        audio_info <- av::av_media_info(temp_output)
        total_duration <- audio_info$duration
        num_parts <- ceiling(file_size_mb / max_size_mb)
        part_duration <- total_duration / num_parts
        
        output_files <- character()
        total_output_size <- 0
        
        for (i in 1:num_parts) {
          start_time <- (i - 1) * part_duration
          part_filename <- paste0(base_filename, "_part", sprintf("%02d", i), ".mp3")
          part_output <- file.path(output_dir, part_filename)
          
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
      if (exists("temp_output") && file.exists(temp_output)) {
        file.remove(temp_output)
      }
      
      return(list(
        success = FALSE,
        error = e$message
      ))
    })
  }
  
  # CONVERTER FUNCTIONALITY
  observeEvent(input$convertBtn, {
    req(input$m4aFile)
    req(input$m4aFile$datapath)
    req(input$m4aFile$name)
    
    output_dir <- values$converter_output_dir
    if (is.null(output_dir) || !dir.exists(output_dir)) {
      showNotification("Please select a valid output directory", type = "error")
      return()
    }
    
    values$conversion_complete <- FALSE
    output$conversionStatus <- renderText("🔄 Starting conversion...")
    
    tryCatch({
      start_time <- Sys.time()
      
      input_path <- input$m4aFile$datapath
      input_name <- input$m4aFile$name
      quality <- input$mp3Quality
      max_size_mb <- input$converter_max_size_mb
      input_size_mb <- input$m4aFile$size / (1024^2)
      base_name <- tools::file_path_sans_ext(input_name)
      
      output$conversionStatus <- renderText(paste(
        "⚡ Converting audio...\n\n",
        "Output directory:", output_dir, "\n",
        "Max file size:", max_size_mb, "MB"
      ))
      
      conversion_result <- convertM4AtoMP3WithSplit(input_path, output_dir, base_name, quality, max_size_mb)
      
      if (!conversion_result$success) {
        stop(conversion_result$error)
      }
      
      end_time <- Sys.time()
      conversion_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
      
      if (conversion_result$split) {
        output$conversionStatus <- renderText(paste(
          "✅ Conversion completed with auto-split!\n\n",
          "Files created:", conversion_result$parts, "parts\n",
          "Max size per file:", max_size_mb, "MB\n",
          "Output directory:", output_dir
        ))
      } else {
        output$conversionStatus <- renderText(paste(
          "✅ Conversion completed!\n\n",
          "File created:", conversion_result$files, "\n",
          "File size:", round(conversion_result$total_size, 2), "MB\n",
          "No splitting needed (<", max_size_mb, "MB)\n",
          "Output directory:", output_dir
        ))
      }
      
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
      
      output$convertedFileInfo <- renderText({
        compression_ratio <- round(input_size_mb / conversion_result$total_size, 2)
        
        if (conversion_result$split) {
          paste(
            "🔄 CONVERSION WITH AUTO-SPLIT:\n\n",
            "📥 Original:", round(input_size_mb, 2), "MB\n",
            "📤 Total output:", round(conversion_result$total_size, 2), "MB\n",
            "✂️ Parts created:", conversion_result$parts, "files\n",
            "📏 Max size per file:", max_size_mb, "MB\n",
            "⚙️ Quality:", quality, "\n",
            "⏱️ Time:", round(conversion_time, 2), "seconds\n",
            "📊 Compression:", compression_ratio, ":1\n\n",
            "📁 FILES CREATED:\n",
            paste("•", conversion_result$files, collapse = "\n"), "\n\n",
            "💡 Each part is under", max_size_mb, "MB for easy handling!\n",
            "📂 Location:", output_dir
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
            "✅ No splitting needed - file is under", max_size_mb, "MB!\n",
            "📂 Location:", output_dir
          )
        }
      })
      
      showNotification("Conversion completed!", type = "message")
      
    }, error = function(e) {
      values$conversion_complete <- FALSE
      output$conversionStatus <- renderText(paste("❌ Error:", e$message))
      showNotification(paste("Conversion Error:", e$message), type = "error")
    })
  })
  
  # Open converter output folder
  observeEvent(input$openConverterFolderBtn, {
    output_dir <- values$converter_output_dir
    tryCatch({
      if (.Platform$OS.type == "windows") {
        shell.exec(output_dir)
      } else {
        system(paste("open", shQuote(output_dir)))
      }
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
      file_ext <- tolower(tools::file_ext(file_name))
      
      if (file_ext == "mp3") {
        values$audio_data <- readMP3(file_path)
      } else if (file_ext == "wav") {
        values$audio_data <- readWave(file_path)
      } else {
        stop("Unsupported file format.")
      }
      
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
                                      "✓ Audio file loaded!\n",
                                      "Duration:", round(duration_sec, 2), "seconds\n")
      
    }, error = function(e) {
      values$processing_log <- paste0(values$processing_log, 
                                      "✗ Error:", e$message, "\n")
      values$audio_data <- NULL
      values$audio_info <- NULL
    })
  })
  
  # Display audio information
  output$audio_info <- renderText({
    if (!is.null(values$audio_info)) {
      paste0(
        "File: ", values$audio_info$original_name, "\n",
        "Duration: ", round(values$audio_info$duration, 2), " seconds\n",
        "Sample Rate: ", values$audio_info$sample_rate, " Hz\n",
        "Channels: ", values$audio_info$channels
      )
    } else {
      "No audio file uploaded."
    }
  })
  
  # Show duration inputs
  output$show_duration_inputs <- reactive({
    !is.null(values$audio_info) && input$split_method == "num_files" && !input$equal_duration
  })
  outputOptions(output, "show_duration_inputs", suspendWhenHidden = FALSE)
  
  # Generate duration input controls
  output$duration_inputs <- renderUI({
    req(values$audio_info, input$split_method == "num_files", !input$equal_duration, input$num_splits >= 2)
    
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
    req(values$audio_data, input$output_folder != "")
    
    if (input$split_method == "num_files") {
      req(input$num_splits >= 2)
    } else if (input$split_method == "file_size") {
      req(input$splitter_max_size_mb >= 1)
    }
    
    base_output_dir <- values$splitter_output_dir
    if (is.null(base_output_dir) || !dir.exists(base_output_dir)) {
      showNotification("Please select a valid output directory", type = "error")
      return()
    }
    
    values$processing_log <- "=== Starting Audio Split ===\n"
    
    tryCatch({
      duration <- values$audio_info$duration
      sample_rate <- values$audio_info$sample_rate
      bit_depth <- values$audio_info$bit_depth
      num_channels <- values$audio_info$channels
      
      output_folder <- trimws(input$output_folder)
      values$output_dir <- file.path(base_output_dir, output_folder)
      
      if (dir.exists(values$output_dir)) {
        unlink(values$output_dir, recursive = TRUE)
      }
      dir.create(values$output_dir, recursive = TRUE)
      
      values$processing_log <- paste0(values$processing_log, 
                                      "✓ Created:", values$output_dir, "\n")
      
      if (input$split_method == "file_size") {
        bytes_per_second <- sample_rate * (bit_depth / 8) * num_channels
        max_bytes <- input$splitter_max_size_mb * 1024 * 1024 - 1024
        max_duration_per_segment <- max_bytes / bytes_per_second
        num_segments <- ceiling(duration / max_duration_per_segment)
        split_points <- seq(0, duration, length.out = num_segments + 1)
        
        values$processing_log <- paste0(values$processing_log, 
                                        "✓ Split by file size (max ", input$splitter_max_size_mb, " MB)\n",
                                        "✓ Estimated segments: ", num_segments, "\n")
      } else {
        if (input$equal_duration) {
          split_duration <- duration / input$num_splits
          split_points <- seq(0, duration, by = split_duration)
          values$processing_log <- paste0(values$processing_log, 
                                          "✓ Using equal duration splits (", 
                                          round(split_duration, 2), " seconds each)\n")
        } else {
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
      }
      
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
      
      values$temp_files <- c()
      
      for (i in 1:(length(split_points) - 1)) {
        start_time <- split_points[i]
        end_time <- split_points[i + 1]
        
        start_sample <- max(1, round(start_time * sample_rate))
        end_sample <- min(length(values$audio_data), round(end_time * sample_rate))
        
        if (values$audio_data@stereo) {
          segment <- values$audio_data[start_sample:end_sample, ]
        } else {
          segment <- values$audio_data[start_sample:end_sample]
        }
        
        file_extension <- input$output_format
        filename <- paste0(input$output_prefix, "_", 
                           sprintf("%02d", i), ".", file_extension)
        filepath <- file.path(values$output_dir, filename)
        
        tryCatch({
          writeWave(segment, filepath)
          file_size <- file.size(filepath)
          status <- "✓ Success"
          values$temp_files <- c(values$temp_files, filepath)
          
        }, error = function(e) {
          status <- paste("✗ Error:", e$message)
          file_size <- 0
        })
        
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
      
      if (input$split_method == "file_size") {
        values$processing_log <- paste0(values$processing_log, 
                                        "\n✅ Created ", success_count, " segments\n",
                                        "Max file size: ", input$splitter_max_size_mb, " MB per file\n",
                                        "Location: ", values$output_dir, "\n")
      } else {
        values$processing_log <- paste0(values$processing_log, 
                                        "\n✅ Created ", success_count, " segments\n",
                                        "Location: ", values$output_dir, "\n")
      }
      
    }, error = function(e) {
      values$processing_log <- paste0(values$processing_log, 
                                      "✗ Error:", e$message, "\n")
    })
  })
  
  # Display processing log
  output$process_log <- renderText({
    values$processing_log
  })
  
  # Show output location
  output$output_location <- renderText({
    req(values$output_dir)
    values$output_dir
  })
  
  # Show results
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
              rownames = FALSE)
  })
  
  # Download handler for ZIP
  output$download_zip <- downloadHandler(
    filename = function() {
      paste0("split_audio_", Sys.Date(), ".zip")
    },
    content = function(file) {
      temp_zip <- tempfile(fileext = ".zip")
      
      if (length(values$temp_files) > 0) {
        zip(temp_zip, values$temp_files, flags = "-j")
        file.copy(temp_zip, file)
      }
    },
    contentType = "application/zip"
  )
  
  # Open splitter output folder
  observeEvent(input$openSplitterFolderBtn, {
    req(values$output_dir)
    dir_to_open <- values$output_dir
    tryCatch({
      if (.Platform$OS.type == "windows") {
        shell.exec(dir_to_open)
      } else {
        system(paste("open", shQuote(dir_to_open)))
      }
    }, error = function(e) {
      showNotification("Could not open folder", type = "warning")
    })
  })
  
  # ==================== ANALYTICS ====================
  
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
    valueBox(
      value = paste(round(avg_time, 2), "s"),
      subtitle = "Avg Processing Time",
      icon = icon("clock"),
      color = "yellow"
    )
  })
  
  output$wordCountPlot <- renderPlotly({
    req(nrow(values$transcriptions) > 0)
    
    plot_ly(
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
        yaxis = list(title = "Word Count")
      )
  })
  
  output$processingTimePlot <- renderPlotly({
    req(nrow(values$transcriptions) > 0)
    
    plot_ly(
      x = seq_len(nrow(values$transcriptions)),
      y = values$transcriptions$processing_time,
      type = "bar",
      marker = list(color = "#11998e")
    ) %>%
      layout(
        title = "Processing Time by File",
        xaxis = list(title = "File Number"),
        yaxis = list(title = "Time (seconds)")
      )
  })
  
  output$historyTable <- DT::renderDataTable({
    req(nrow(values$transcriptions) > 0)
    datatable(values$transcriptions, options = list(pageLength = 10))
  })
  
  output$conversionHistoryTable <- DT::renderDataTable({
    req(nrow(values$conversions) > 0)
    datatable(values$conversions, options = list(pageLength = 10))
  })
  
  # Clean up on session end
  session$onSessionEnded(function() {
    if (!is.null(values$output_dir) && dir.exists(values$output_dir)) {
      if (grepl(tempdir(), values$output_dir, fixed = TRUE)) {
        unlink(values$output_dir, recursive = TRUE)
      }
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)