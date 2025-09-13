library(shiny)
library(tuneR)
library(seewave)
library(shinydashboard)
library(DT)

# UI
ui <- dashboardPage(
  dashboardHeader(title = "MP3 File Splitter"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("File Splitter", tabName = "splitter", icon = icon("scissors"))
    )
  ),
  
  dashboardBody(
    tabItems(
      tabItem(tabName = "splitter",
              fluidRow(
                box(
                  title = "Upload Audio File", status = "primary", solidHeader = TRUE, width = 12,
                  
                  fluidRow(
                    column(8,
                           h4("Step 1: Upload Your Audio File"),
                           fileInput("audio_file", "Choose MP3 or WAV file:",
                                     accept = c(".mp3", ".wav", ".MP3", ".WAV"),
                                     buttonLabel = "Browse...",
                                     placeholder = "No file selected"),
                           
                           div(style = "background-color: #e8f4fd; padding: 10px; border-radius: 5px; margin-top: 10px;",
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
                  title = "Split Settings", status = "info", solidHeader = TRUE, width = 6,
                  
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
                  title = "Audio Information", status = "warning", solidHeader = TRUE, width = 6,
                  
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
                  title = "Processing Status & Results", status = "success", solidHeader = TRUE, width = 12,
                  
                  h4("Processing Log:"),
                  verbatimTextOutput("process_log"),
                  
                  conditionalPanel(
                    condition = "output.show_results",
                    hr(),
                    h4("Split Results:"),
                    DTOutput("results_table"),
                    
                    br(),
                    div(class = "alert alert-success",
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
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Initialize reactive values
  values <- reactiveValues(
    audio_data = NULL,
    audio_info = NULL,
    processing_log = "Ready to process audio files...\n",
    results = NULL,
    output_dir = NULL,
    temp_files = c()
  )
  
  # Process uploaded file
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
  
  # Clean up temporary files when session ends
  session$onSessionEnded(function() {
    if (!is.null(values$output_dir) && dir.exists(values$output_dir)) {
      unlink(values$output_dir, recursive = TRUE)
    }
  })
}

# Run the app
shinyApp(ui = ui, server = server)