splitter_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    # Setup volumes
    volumes <- getAppVolumes()
    shinyDirChoose(input, "browseSplitterDir", roots = volumes, session = session)
    
    # Reactive values
    values <- reactiveValues(
      audio_data = NULL,
      audio_info = NULL,
      processing_log = "Ready to process audio files...\n",
      results = NULL,
      output_dir = NULL,
      temp_files = c(),
      splitter_output_dir = getwd()
    )
    
    # Directory selection
    observeEvent(input$browseSplitterDir, {
      if (!is.null(input$browseSplitterDir) && !is.integer(input$browseSplitterDir)) {
        selected_path <- shinyFiles::parseDirPath(volumes, input$browseSplitterDir)
        if (length(selected_path) > 0) {
          values$splitter_output_dir <- selected_path
          updateTextInput(session, "splitter_output_path", value = selected_path)
          showNotification("Splitter output directory selected", type = "message")
        }
      }
    })
    
    # Process uploaded file
    observeEvent(input$audio_file, {
      req(input$audio_file)
      
      file_path <- input$audio_file$datapath
      file_name <- input$audio_file$name
      
      values$processing_log <- paste0("Uploading file: ", file_name, "\n")
      
      tryCatch({
        file_ext <- tolower(tools::file_ext(file_name))
        
        if (file_ext == "mp3") {
          values$audio_data <- tuneR::readMP3(file_path)
        } else if (file_ext == "wav") {
          values$audio_data <- tuneR::readWave(file_path)
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
                                        "Duration: ", round(duration_sec, 2), " seconds\n")
        
      }, error = function(e) {
        values$processing_log <- paste0(values$processing_log,
                                        "✗ Error: ", e$message, "\n")
        values$audio_data <- NULL
        values$audio_info <- NULL
      })
    })
    
    # Display audio info
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
      !is.null(values$audio_info) && input$split_method == "num_files" &&
        !input$equal_duration
    })
    outputOptions(output, "show_duration_inputs", suspendWhenHidden = FALSE)
    
    # Generate duration input controls
    output$duration_inputs <- renderUI({
      req(values$audio_info, input$split_method == "num_files", !input$equal_duration,
          input$num_splits >= 2)
      
      max_duration <- values$audio_info$duration
      split_points <- input$num_splits - 1
      
      inputs <- lapply(1:split_points, function(i) {
        numericInput(ns(paste0("split_point_", i)),
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
                                        "✓ Created: ", values$output_dir, "\n")
        
        # Determine split points
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
                                            "✓ Using equal duration splits (", round(split_duration, 2), " seconds each)\n")
          } else {
            manual_points <- c()
            for (i in 1:(input$num_splits - 1)) {
              point_value <- input[[paste0("split_point_", i)]]
              if (!is.null(point_value)) {
                manual_points <- c(manual_points, point_value)
              }
            }
            split_points <- c(0, sort(manual_points), duration)
            values$processing_log <- paste0(values$processing_log, "✓ Using custom split points\n")
          }
        }
        
        # Create segments
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
          filename <- paste0(input$output_prefix, "_", sprintf("%02d", i), ".", file_extension)
          filepath <- file.path(values$output_dir, filename)
          
          tryCatch({
            tuneR::writeWave(segment, filepath)
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
        values$processing_log <- paste0(values$processing_log, "✗ Error: ", e$message, "\n")
      })
    })
    
    # Outputs
    output$process_log <- renderText({ values$processing_log })
    
    output$output_location <- renderText({
      req(values$output_dir)
      values$output_dir
    })
    
    output$show_results <- reactive({ !is.null(values$results) })
    outputOptions(output, "show_results", suspendWhenHidden = FALSE)
    
    output$show_download <- reactive({ !is.null(values$results) && length(values$temp_files) > 0 })
    outputOptions(output, "show_download", suspendWhenHidden = FALSE)
    
    output$results_table <- DT::renderDT({
      req(values$results)
      DT::datatable(values$results,
                    options = list(pageLength = 10, scrollX = TRUE, dom = "t"),
                    rownames = FALSE)
    })
    
    # Download ZIP
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
    
    # Open folder
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
  })
}
