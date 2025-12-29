transcription_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    # Setup volumes
    volumes <- getAppVolumes()
    shinyDirChoose(input, "browseTranscriptionDir", roots = volumes, session = session)
    
    # Reactive values
    values <- reactiveValues(
      transcriptions = data.frame(
        timestamp = character(),
        filename = character(),
        word_count = numeric(),
        processing_time = numeric(),
        file_size = numeric(),
        stringsAsFactors = FALSE
      ),
      current_transcription = "",
      transcription_output_dir = getwd()
    )
    
    # Directory selection
    observeEvent(input$browseTranscriptionDir, {
      if (!is.null(input$browseTranscriptionDir) && !is.integer(input$browseTranscriptionDir)) {
        selected_path <- shinyFiles::parseDirPath(volumes, input$browseTranscriptionDir)
        if (length(selected_path) > 0) {
          values$transcription_output_dir <- selected_path
          updateTextInput(session, "transcription_output_path", value = selected_path)
          showNotification("Transcription save directory selected", type = "message")
        }
      }
    })
    
    # File upload status
    output$fileUploaded <- reactive({
      return(!is.null(input$audioFile))
    })
    outputOptions(output, "fileUploaded", suspendWhenHidden = FALSE)
    
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
    
    # Transcribe button event
    observeEvent(input$transcribeBtn, {
      req(input$audioFile)
      
      if (is.null(api_manager$api_key) || nchar(trimws(api_manager$api_key)) == 0) {
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
        
        transcription <- api_manager$transcribe_audio(input$audioFile$datapath, timeout_value)
        
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
    
    # Save transcription
    observeEvent(input$saveBtn, {
      req(values$current_transcription)
      req(input$audioFile)
      
      output_dir <- values$transcription_output_dir
      if (is.null(output_dir) || !dir.exists(output_dir)) {
        showNotification("Please select a valid output directory", type = "error")
        return()
      }
      
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
  })
}
