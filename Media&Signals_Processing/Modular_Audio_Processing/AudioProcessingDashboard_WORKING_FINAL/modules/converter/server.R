converter_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    # Setup volumes for directory browsing
    volumes <- getAppVolumes()
    shinyDirChoose(input, "browseOutputDir", roots = volumes, session = session)
    
    # Reactive values
    values <- reactiveValues(
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
      conversion_complete = FALSE,
      converter_output_dir = getwd()
    )
    
    # Directory selection observer
    observeEvent(input$browseOutputDir, {
      if (!is.null(input$browseOutputDir) && !is.integer(input$browseOutputDir)) {
        selected_path <- shinyFiles::parseDirPath(volumes, input$browseOutputDir)
        if (length(selected_path) > 0) {
          values$converter_output_dir <- selected_path
          updateTextInput(session, "outputPath", value = selected_path)
          showNotification("Output directory selected", type = "message")
        }
      }
    })
    
    # File upload status
    output$m4aFileUploaded <- reactive({
      return(!is.null(input$m4aFile))
    })
    outputOptions(output, "m4aFileUploaded", suspendWhenHidden = FALSE)
    
    # Conversion complete status
    output$conversionComplete <- reactive({
      return(values$conversion_complete)
    })
    outputOptions(output, "conversionComplete", suspendWhenHidden = FALSE)
    
    # File info display
    output$m4aFileInfo <- renderText({
      req(input$m4aFile)
      file_info <- input$m4aFile
      paste(
        "Filename:", file_info$name, "\n",
        "Size:", round(file_info$size / 1024 / 1024, 2), "MB", "\n",
        "Type:", tools::file_ext(file_info$name)
      )
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
          # Need to split
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
    
    # Convert button event
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
              "✂ Parts created:", conversion_result$parts, "files\n",
              "📏 Max size per file:", max_size_mb, "MB\n",
              "⚙ Quality:", quality, "\n",
              "⏱ Time:", round(conversion_time, 2), "seconds\n",
              "📊 Compression:", compression_ratio, ":1\n\n",
              "📁 FILES CREATED:\n",
              paste("•", conversion_result$files, collapse = "\n"), "\n\n",
              "💡 Each part is under", max_size_mb, "MB!\n",
              "📂 Location:", output_dir
            )
          } else {
            paste(
              "🔄 SINGLE FILE CONVERSION:\n\n",
              "📥 Original:", round(input_size_mb, 2), "MB\n",
              "📤 Converted:", round(conversion_result$total_size, 2), "MB\n",
              "⚙ Quality:", quality, "\n",
              "⏱ Time:", round(conversion_time, 2), "seconds\n",
              "📊 Compression:", compression_ratio, ":1\n",
              "📁 File:", conversion_result$files, "\n\n",
              "✅ No splitting needed!\n",
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
    
    # Open output folder
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
    
    # Conversion history table
    output$conversionHistoryTable <- DT::renderDataTable({
      req(nrow(values$conversions) > 0)
      DT::datatable(values$conversions, options = list(pageLength = 10))
    })
  })
}
