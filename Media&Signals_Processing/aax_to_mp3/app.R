library(shiny)
library(shinydashboard)
library(DT)
library(av)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "AAX to MP3 Converter"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("File Converter", tabName = "converter", icon = icon("exchange-alt"))
    )
  ),
  
  dashboardBody(
    # Remove file size limits
    tags$head(
      tags$script('
        Shiny.addCustomMessageHandler("unlimited-upload", function(message) {
          $("input[type=file]").attr("data-max-file-size", "unlimited");
        });
      ')
    ),
    tabItems(
      tabItem(tabName = "converter",
              fluidRow(
                # Input section
                box(
                  title = "File Input", status = "primary", solidHeader = TRUE, width = 6,
                  
                  # FFmpeg status check
                  conditionalPanel(
                    condition = "!output.ffmpeg_available",
                    div(class = "alert alert-warning",
                        strong("FFmpeg Required!"), br(),
                        "Please install FFmpeg before using this app:", br(),
                        strong("Windows:"), " Download from https://ffmpeg.org or use: ", code("winget install ffmpeg"), br(),
                        strong("macOS:"), " ", code("brew install ffmpeg"), br(),
                        strong("Linux:"), " ", code("sudo apt install ffmpeg"), " or ", code("sudo yum install ffmpeg")
                    )
                  ),
                  
                  fileInput("aax_file", "Choose AAX File",
                            accept = c(".aax")),
                  
                  textInput("output_name", "Output filename (without extension)", 
                            value = "converted_audio"),
                  
                  textInput("activation_bytes", "Activation Bytes (Required for DRM files)", 
                            value = "", placeholder = "e.g., 1234abcd"),
                  
                  helpText("Note: Most AAX files from Audible are DRM-protected and require activation bytes. ",
                           "You can find your activation bytes using tools like 'audible-activator' or by ",
                           "checking your Audible account settings."),
                  
                  br(),
                  actionButton("convert_btn", "Convert to MP3", 
                               class = "btn-primary", icon = icon("play"))
                ),
                
                # Status section
                box(
                  title = "Conversion Status", status = "info", solidHeader = TRUE, width = 6,
                  verbatimTextOutput("status_output"),
                  
                  br(),
                  conditionalPanel(
                    condition = "output.conversion_complete",
                    downloadButton("download_mp3", "Download MP3", 
                                   class = "btn-success", icon = icon("download"))
                  )
                )
              ),
              
              fluidRow(
                # Audio info section
                box(
                  title = "Audio Information", status = "warning", solidHeader = TRUE, width = 12,
                  conditionalPanel(
                    condition = "output.show_audio_info",
                    h4("File Properties:"),
                    verbatimTextOutput("audio_info")
                  )
                )
              ),
              
              fluidRow(
                # Metadata visualization
                box(
                  title = "Metadata Visualization", status = "success", solidHeader = TRUE, width = 12,
                  conditionalPanel(
                    condition = "output.show_metadata",
                    h4("Extracted Metadata:"),
                    DT::dataTableOutput("metadata_table"),
                    
                    br(),
                    h4("Metadata Summary:"),
                    fluidRow(
                      valueBoxOutput("duration_box"),
                      valueBoxOutput("bitrate_box"),
                      valueBoxOutput("channels_box")
                    )
                  )
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Reactive values to store file paths and metadata
  values <- reactiveValues(
    input_file = NULL,
    output_file = NULL,
    metadata = NULL,
    audio_info = NULL,
    conversion_complete = FALSE
  )
  
  # Handle file upload
  observeEvent(input$aax_file, {
    req(input$aax_file)
    values$input_file <- input$aax_file$datapath
    
    # Try to read audio info (may fail with DRM-protected files)
    tryCatch({
      values$audio_info <- av_media_info(values$input_file)
      values$metadata <- values$audio_info
    }, error = function(e) {
      values$audio_info <- paste("Error reading file info:", e$message)
      values$metadata <- NULL
    })
  })
  
  # Check if FFmpeg is available
  ffmpeg_available <- reactive({
    result <- tryCatch({
      system("ffmpeg -version", intern = TRUE, ignore.stderr = TRUE)
      TRUE
    }, error = function(e) {
      FALSE
    })
    return(result)
  })
  
  # Handle conversion
  observeEvent(input$convert_btn, {
    req(input$aax_file, input$output_name)
    
    # Check if FFmpeg is available
    if (!ffmpeg_available()) {
      showNotification("FFmpeg not found. Please install FFmpeg first.", 
                       type = "error", duration = 15)
      return()
    }
    
    # Reset conversion status
    values$conversion_complete <- FALSE
    
    # Create output filename
    output_filename <- paste0(input$output_name, ".mp3")
    temp_output <- file.path(tempdir(), output_filename)
    
    withProgress(message = 'Converting file...', value = 0, {
      tryCatch({
        incProgress(0.3, detail = "Starting conversion...")
        
        # Always try to use system call with ffmpeg for AAX files
        if (nchar(input$activation_bytes) > 0) {
          # With activation bytes
          cmd <- sprintf('ffmpeg -activation_bytes %s -i "%s" -codec:a libmp3lame -b:a 128k "%s"', 
                         input$activation_bytes, values$input_file, temp_output)
        } else {
          # Try without activation bytes (for non-DRM files)
          cmd <- sprintf('ffmpeg -i "%s" -codec:a libmp3lame -b:a 128k "%s"', 
                         values$input_file, temp_output)
        }
        
        incProgress(0.5, detail = "Processing with FFmpeg...")
        
        # Execute FFmpeg command
        result <- system(cmd, intern = TRUE, ignore.stderr = FALSE)
        
        if (!file.exists(temp_output)) {
          if (nchar(input$activation_bytes) == 0) {
            stop("Conversion failed. This AAX file appears to be DRM-protected. Please provide activation bytes.")
          } else {
            stop("Conversion failed. Please check your activation bytes and try again.")
          }
        }
        
        incProgress(0.9, detail = "Finalizing...")
        
        values$output_file <- temp_output
        values$conversion_complete <- TRUE
        
        # Try to get metadata from converted file
        tryCatch({
          values$metadata <- av_media_info(temp_output)
        }, error = function(e) {
          # Keep original metadata if available
          values$metadata <- list(duration = "Unknown", audio = list())
        })
        
        incProgress(1, detail = "Complete!")
        showNotification("Conversion completed successfully!", type = "message")
        
      }, error = function(e) {
        error_msg <- as.character(e$message)
        if (grepl("activation_bytes|Invalid data", error_msg, ignore.case = TRUE)) {
          showNotification("This AAX file is DRM-protected. Please enter your activation bytes.", 
                           type = "error", duration = 10)
        } else if (grepl("ffmpeg.*not found", error_msg, ignore.case = TRUE)) {
          showNotification("FFmpeg not found. Please install FFmpeg first.", 
                           type = "error", duration = 15)
        } else {
          showNotification(paste("Conversion failed:", error_msg), type = "error", duration = 10)
        }
      })
    })
  })
  
  # Status output
  output$status_output <- renderText({
    if (is.null(input$aax_file)) {
      "Please select an AAX file to convert."
    } else if (!values$conversion_complete) {
      "File loaded. Click 'Convert to MP3' to start conversion."
    } else {
      "Conversion completed successfully! File ready for download."
    }
  })
  
  # Audio info output
  output$audio_info <- renderText({
    if (!is.null(values$audio_info)) {
      if (is.character(values$audio_info)) {
        values$audio_info
      } else {
        paste(capture.output(str(values$audio_info)), collapse = "\n")
      }
    }
  })
  
  # Metadata table
  output$metadata_table <- DT::renderDataTable({
    if (!is.null(values$metadata) && is.list(values$metadata)) {
      # Convert metadata to a readable format
      metadata_df <- data.frame(
        Property = character(),
        Value = character(),
        stringsAsFactors = FALSE
      )
      
      # Extract common metadata fields
      if ("duration" %in% names(values$metadata)) {
        metadata_df <- rbind(metadata_df, 
                             data.frame(Property = "Duration (seconds)", 
                                        Value = as.character(values$metadata$duration)))
      }
      
      if ("audio" %in% names(values$metadata) && length(values$metadata$audio) > 0) {
        audio_info <- values$metadata$audio[[1]]
        for (field in names(audio_info)) {
          metadata_df <- rbind(metadata_df,
                               data.frame(Property = paste("Audio", field),
                                          Value = as.character(audio_info[[field]])))
        }
      }
      
      # Add any other metadata
      other_fields <- setdiff(names(values$metadata), c("duration", "audio", "video"))
      for (field in other_fields) {
        metadata_df <- rbind(metadata_df,
                             data.frame(Property = field,
                                        Value = as.character(values$metadata[[field]])))
      }
      
      DT::datatable(metadata_df, options = list(pageLength = 10, dom = 't'))
    }
  })
  
  # Value boxes for key metrics
  output$duration_box <- renderValueBox({
    duration <- if (!is.null(values$metadata) && "duration" %in% names(values$metadata)) {
      paste(round(values$metadata$duration / 60, 1), "min")
    } else {
      "N/A"
    }
    
    valueBox(
      value = duration,
      subtitle = "Duration",
      icon = icon("clock"),
      color = "blue"
    )
  })
  
  output$bitrate_box <- renderValueBox({
    bitrate <- if (!is.null(values$metadata) && 
                   "audio" %in% names(values$metadata) && 
                   length(values$metadata$audio) > 0 &&
                   "bitrate" %in% names(values$metadata$audio[[1]])) {
      paste(values$metadata$audio[[1]]$bitrate, "bps")
    } else {
      "N/A"
    }
    
    valueBox(
      value = bitrate,
      subtitle = "Bitrate",
      icon = icon("signal"),
      color = "green"
    )
  })
  
  output$channels_box <- renderValueBox({
    channels <- if (!is.null(values$metadata) && 
                    "audio" %in% names(values$metadata) && 
                    length(values$metadata$audio) > 0 &&
                    "channels" %in% names(values$metadata$audio[[1]])) {
      values$metadata$audio[[1]]$channels
    } else {
      "N/A"
    }
    
    valueBox(
      value = channels,
      subtitle = "Channels",
      icon = icon("volume-up"),
      color = "yellow"
    )
  })
  
  # Download handler
  output$download_mp3 <- downloadHandler(
    filename = function() {
      paste0(input$output_name, ".mp3")
    },
    content = function(file) {
      if (!is.null(values$output_file) && file.exists(values$output_file)) {
        file.copy(values$output_file, file)
      }
    },
    contentType = "audio/mpeg"
  )
  
  # FFmpeg availability output
  output$ffmpeg_available <- reactive({
    ffmpeg_available()
  })
  outputOptions(output, "ffmpeg_available", suspendWhenHidden = FALSE)
  
  # Conditional outputs
  output$conversion_complete <- reactive({
    values$conversion_complete
  })
  outputOptions(output, "conversion_complete", suspendWhenHidden = FALSE)
  
  output$show_audio_info <- reactive({
    !is.null(values$audio_info)
  })
  outputOptions(output, "show_audio_info", suspendWhenHidden = FALSE)
  
  output$show_metadata <- reactive({
    !is.null(values$metadata)
  })
  outputOptions(output, "show_metadata", suspendWhenHidden = FALSE)
}

# Run the application with increased upload limit
options(shiny.maxRequestSize = -1)  # Remove file size limit
shinyApp(ui = ui, server = server)