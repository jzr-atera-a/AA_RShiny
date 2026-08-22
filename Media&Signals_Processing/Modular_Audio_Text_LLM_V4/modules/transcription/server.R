transcription_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    volumes <- get_volume_roots()
    shinyDirChoose(input, "browseDir", roots = volumes, session = session)
    
    values <- reactiveValues(save_dir = getwd(), transcription = "")
    
    observeEvent(input$browseDir, {
      if (!is.integer(input$browseDir)) {
        selected <- parseDirPath(volumes, input$browseDir)
        if (length(selected) > 0) {
          values$save_dir <- selected
          updateTextInput(session, "savePath", value = selected)
        }
      }
    })
    
    output$fileInfo <- renderText({
      req(input$audioFiles)
      num <- nrow(input$audioFiles)
      if (num > 10) return("⚠ Max 10 files")
      total_mb <- sum(input$audioFiles$size) / 1024 / 1024
      paste("Files:", num, "\nTotal size:", round(total_mb, 2), "MB")
    })
    
    observeEvent(input$transcribeBtn, {
      req(input$audioFiles)
      
      cat("\n", rep("=", 60), "\n", sep = "")
      cat("🎙️  BATCH TRANSCRIPTION STARTED\n")
      cat(rep("=", 60), "\n", sep = "")
      flush.console()
      
      # Check API key
      if (nchar(trimws(api_manager$whisper_api_key)) == 0) {
        cat("❌ Whisper API key not set\n\n")
        flush.console()
        
        output$status <- renderText("❌ No Whisper API key set\n\nPlease configure it in 'Whisper API Settings' tab")
        showNotification("Please set Whisper API key first", type = "error", duration = 10)
        return()
      }
      
      api_key_preview <- paste0(
        substr(api_manager$whisper_api_key, 1, 7), "...",
        substr(api_manager$whisper_api_key, nchar(api_manager$whisper_api_key)-3, nchar(api_manager$whisper_api_key))
      )
      
      cat("✅ Whisper API key found:", api_key_preview, "\n")
      flush.console()
      
      num_files <- nrow(input$audioFiles)
      if (num_files > 10) {
        cat("❌ Too many files:", num_files, "\n\n")
        flush.console()
        output$status <- renderText("❌ Max 10 files allowed")
        showNotification("Please select up to 10 files only", type = "error")
        return()
      }
      
      # CRITICAL FIX: Properly check if timeout is enabled
      use_timeout <- isTRUE(input$useTimeout)
      
      timeout_val <- NULL
      if (use_timeout) {
        if (!is.null(input$timeout) && is.numeric(input$timeout) && input$timeout > 0) {
          timeout_val <- input$timeout
        }
      }
      
      cat("Files to process:", num_files, "\n")
      cat("Timeout checkbox:", use_timeout, "\n")
      cat("Timeout value:", if(is.null(timeout_val)) "NULL (unlimited)" else paste(timeout_val, "seconds"), "\n")
      cat(rep("=", 60), "\n\n", sep = "")
      flush.console()
      
      # Initial status
      output$status <- renderText(paste0(
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n",
        "🔄 INITIALIZING BATCH TRANSCRIPTION\n",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n",
        "✓ API Key: ", api_key_preview, "\n",
        "✓ Files to process: ", num_files, "\n",
        "✓ Timeout: ", if(use_timeout && !is.null(timeout_val)) paste(timeout_val, "sec") else "UNLIMITED", "\n\n",
        "Starting transcription...\n"
      ))
      
      all_transcriptions <- character()
      total_words <- 0
      overall_start <- Sys.time()
      
      tryCatch({
        for (i in 1:num_files) {
          file_name <- input$audioFiles$name[i]
          file_path <- input$audioFiles$datapath[i]
          file_size_mb <- round(input$audioFiles$size[i] / 1024 / 1024, 2)
          
          cat("\n📁 FILE ", i, " of ", num_files, ": ", file_name, "\n", sep = "")
          cat("   Size: ", file_size_mb, " MB\n", sep = "")
          cat("   Timeout: ", if(use_timeout && !is.null(timeout_val)) paste(timeout_val, "sec") else "UNLIMITED", "\n", sep = "")
          flush.console()
          
          # UI UPDATE - Processing file
          output$status <- renderText(paste0(
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n",
            "📤 PROCESSING FILE ", i, " of ", num_files, "\n",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n",
            "File: ", file_name, "\n",
            "Size: ", file_size_mb, " MB\n\n",
            "Status:\n",
            "  🔄 Preparing file...\n"
          ))
          
          Sys.sleep(0.3)
          
          # UI UPDATE - Uploading
          output$status <- renderText(paste0(
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n",
            "📤 PROCESSING FILE ", i, " of ", num_files, "\n",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n",
            "File: ", file_name, "\n",
            "Size: ", file_size_mb, " MB\n\n",
            "Status:\n",
            "  📤 Uploading to Whisper API...\n",
            "  ⏳ Waiting for transcription...\n",
            if(use_timeout && !is.null(timeout_val)) {
              paste0("  ⏱️  Max wait: ", timeout_val, " seconds\n")
            } else {
              "  ♾️  No timeout (24 hour limit)\n"
            },
            "\n🔴 DO NOT CLOSE THIS WINDOW\n"
          ))
          
          cat("   📤 Sending to Whisper API...\n")
          if (use_timeout && !is.null(timeout_val)) {
            cat("   ⏱️  Timeout:", timeout_val, "seconds\n")
          } else {
            cat("   ♾️  No timeout (24 hour limit)\n")
          }
          flush.console()
          
          file_start <- Sys.time()
          
          # Make API call with proper timeout handling
          transcription <- api_manager$transcribe_audio(file_path, use_timeout, timeout_val)
          
          file_end <- Sys.time()
          file_time <- as.numeric(difftime(file_end, file_start, units = "secs"))
          
          cat("   ✅ Complete: ", nchar(transcription), " chars in ", round(file_time, 2), " sec\n", sep = "")
          flush.console()
          
          file_header <- paste0("\n\n=== FILE ", i, ": ", file_name, " ===\n\n")
          all_transcriptions <- c(all_transcriptions, paste0(file_header, transcription))
          
          combined <- paste(all_transcriptions, collapse = "\n")
          updateTextAreaInput(session, "results", value = combined)
          values$transcription <- combined
          
          file_words <- length(strsplit(trimws(transcription), "\\s+")[[1]])
          total_words <- total_words + file_words
          
          new_row <- data.frame(
            timestamp = as.character(Sys.time()),
            filename = file_name,
            word_count = file_words,
            processing_time = round(file_time, 2),
            file_size = file_size_mb,
            stringsAsFactors = FALSE
          )
          api_manager$transcriptions <- rbind(api_manager$transcriptions, new_row)
          
          # UI UPDATE - File complete
          output$status <- renderText(paste0(
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n",
            "✅ COMPLETED FILE ", i, " of ", num_files, "\n",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n",
            "File: ", file_name, "\n",
            "Words: ", format(file_words, big.mark = ","), "\n",
            "Time: ", round(file_time, 2), " seconds\n\n",
            "BATCH PROGRESS:\n",
            "  ✓ Completed: ", i, " / ", num_files, " files\n",
            "  📝 Total words so far: ", format(total_words, big.mark = ","), "\n\n",
            if(i < num_files) "Proceeding to next file..." else "All files processed!"
          ))
          
          if (i < num_files) Sys.sleep(1)
        }
        
        overall_end <- Sys.time()
        total_time <- as.numeric(difftime(overall_end, overall_start, units = "secs"))
        
        cat("\n", rep("=", 60), "\n", sep = "")
        cat("✅ BATCH TRANSCRIPTION COMPLETE\n")
        cat(rep("=", 60), "\n", sep = "")
        cat("Total files:", num_files, "\n")
        cat("Total words:", format(total_words, big.mark = ","), "\n")
        cat("Total time:", round(total_time, 2), "seconds\n")
        cat("Average per file:", round(total_time / num_files, 2), "seconds\n")
        cat(rep("=", 60), "\n\n", sep = "")
        flush.console()
        
        # FINAL UI UPDATE
        output$status <- renderText(paste0(
          "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n",
          "✅ ✅ ✅ ALL TRANSCRIPTIONS COMPLETE! ✅ ✅ ✅\n",
          "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n",
          "📊 SUMMARY:\n\n",
          "Files processed: ", num_files, "\n",
          "Total words: ", format(total_words, big.mark = ","), "\n",
          "Total time: ", round(total_time, 2), " seconds\n",
          "Average per file: ", round(total_time / num_files, 2), " seconds\n",
          "Words per second: ", round(total_words / total_time, 1), "\n\n",
          "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n",
          "✓ Transcriptions ready in text area\n",
          "✓ Ready to save to file\n"
        ))
        
        showNotification(
          paste("✅ All", num_files, "files transcribed! Total:", total_words, "words"), 
          type = "message", 
          duration = 5
        )
        
      }, error = function(e) {
        cat("\n", rep("=", 60), "\n", sep = "")
        cat("❌ ERROR DURING TRANSCRIPTION\n")
        cat(rep("=", 60), "\n", sep = "")
        cat("Error message:", e$message, "\n")
        cat("API Key set:", nchar(api_manager$whisper_api_key) > 0, "\n")
        cat("Files selected:", num_files, "\n")
        cat(rep("=", 60), "\n\n", sep = "")
        flush.console()
        
        output$status <- renderText(paste0(
          "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n",
          "❌ ERROR OCCURRED\n",
          "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n",
          "Error: ", e$message, "\n\n",
          "Files completed before error: ", length(all_transcriptions), " of ", num_files, "\n\n",
          "TROUBLESHOOTING:\n\n",
          "1. Check R console for detailed error\n",
          "2. Verify Whisper API key in settings\n",
          "3. Test API connection in settings tab\n",
          "4. Check file size (max 25 MB per file)\n",
          "5. Try with smaller files\n",
          "6. Try enabling timeout (180 seconds)\n"
        ))
        
        showNotification(
          paste("❌ Transcription failed:", substr(e$message, 1, 100)), 
          type = "error", 
          duration = 15
        )
        
        # Save partial results if any
        if (length(all_transcriptions) > 0) {
          combined <- paste(all_transcriptions, collapse = "\n")
          updateTextAreaInput(session, "results", value = combined)
          values$transcription <- combined
        }
      })
    })
    
    observeEvent(input$saveBtn, {
      req(values$transcription)
      req(input$audioFiles)
      
      num <- nrow(input$audioFiles)
      filename <- if(num == 1) {
        paste0(tools::file_path_sans_ext(input$audioFiles$name[1]), ".txt")
      } else {
        paste0("batch_transcription_", num, "files_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")
      }
      
      save_path <- file.path(values$save_dir, filename)
      
      tryCatch({
        writeLines(values$transcription, save_path)
        cat("💾 Transcription saved to:", save_path, "\n\n")
        flush.console()
        showNotification(paste("Saved to:", save_path), type = "message")
      }, error = function(e) {
        cat("❌ Error saving:", e$message, "\n\n")
        flush.console()
        showNotification(paste("Error saving:", e$message), type = "error")
      })
    })
  })
}