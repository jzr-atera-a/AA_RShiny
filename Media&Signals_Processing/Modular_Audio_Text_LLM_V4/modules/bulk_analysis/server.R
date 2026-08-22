bulk_analysis_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    volumes <- get_volume_roots()
    shinyDirChoose(input, "browseDir", roots = volumes, session = session)
    shinyDirChoose(input, "browseSaveDir", roots = volumes, session = session)
    
    values <- reactiveValues(folder_dir = NULL, save_dir = getwd(), files = NULL, summary = "", concatenated = NULL)
    
    observeEvent(input$browseDir, {
      if (!is.integer(input$browseDir)) {
        selected <- parseDirPath(volumes, input$browseDir)
        if (length(selected) > 0) {
          values$folder_dir <- selected
          updateTextInput(session, "folderPath", value = selected)
        }
      }
    })
    
    observeEvent(input$browseSaveDir, {
      if (!is.integer(input$browseSaveDir)) {
        selected <- parseDirPath(volumes, input$browseSaveDir)
        if (length(selected) > 0) {
          values$save_dir <- selected
          updateTextInput(session, "savePath", value = selected)
        }
      }
    })
    
    observeEvent(input$scanBtn, {
      req(values$folder_dir)
      
      cat("\n📂 Scanning folder for .txt files...\n")
      cat("   Path:", values$folder_dir, "\n")
      flush.console()
      
      txt_files <- list.files(values$folder_dir, pattern = "\\.txt$", full.names = TRUE, ignore.case = TRUE)
      
      if (length(txt_files) == 0) {
        cat("   ⚠ No .txt files found\n\n")
        flush.console()
        showNotification("No .txt files found in selected folder", type = "warning")
        return()
      }
      
      values$files <- data.frame(
        filename = basename(txt_files),
        path = txt_files,
        size = file.size(txt_files),
        stringsAsFactors = FALSE
      )
      
      cat("   ✅ Found", length(txt_files), "file(s)\n")
      cat("   Total size:", round(sum(values$files$size) / 1024, 2), "KB\n\n")
      flush.console()
      
      output$folderContents <- renderUI({
        tagList(
          h5(paste("Found", length(txt_files), "text file(s)")),
          p(paste("Total size:", round(sum(values$files$size) / 1024, 2), "KB")),
          tags$ul(lapply(1:min(10, length(txt_files)), function(i) {
            tags$li(paste0(values$files$filename[i], " (", round(values$files$size[i] / 1024, 2), " KB)"))
          })),
          if(length(txt_files) > 10) p(paste("... and", length(txt_files) - 10, "more files"))
        )
      })
      
      showNotification(paste("Found", length(txt_files), "file(s)"), type = "message")
    })
    
    observeEvent(input$analyzeBtn, {
      req(values$files)
      
      cat("\n", rep("=", 60), "\n", sep = "")
      cat("📊 BULK ANALYSIS STARTED\n")
      cat(rep("=", 60), "\n", sep = "")
      flush.console()
      
      # Check API key
      if (nchar(trimws(api_manager$chatgpt_api_key)) == 0) {
        cat("❌ ChatGPT API key not set\n\n")
        flush.console()
        
        output$status <- renderText("❌ ChatGPT API key not set\n\nPlease configure it in 'ChatGPT API Settings' tab")
        showNotification("Please set ChatGPT API key first", type = "error", duration = 10)
        return()
      }
      
      api_key_preview <- paste0(
        substr(api_manager$chatgpt_api_key, 1, 7), "...",
        substr(api_manager$chatgpt_api_key, nchar(api_manager$chatgpt_api_key)-3, nchar(api_manager$chatgpt_api_key))
      )
      
      cat("✅ ChatGPT API key found:", api_key_preview, "\n")
      flush.console()
      
      # CRITICAL FIX: Properly check if timeout is enabled
      use_timeout <- isTRUE(input$useTimeout)
      
      timeout_val <- NULL
      if (use_timeout) {
        if (!is.null(input$timeout) && is.numeric(input$timeout) && input$timeout > 0) {
          timeout_val <- input$timeout
        }
      }
      
      cat("Files to process:", nrow(values$files), "\n")
      cat("Timeout checkbox:", use_timeout, "\n")
      cat("Timeout value:", if(is.null(timeout_val)) "NULL (unlimited)" else paste(timeout_val, "seconds"), "\n")
      cat(rep("=", 60), "\n\n", sep = "")
      flush.console()
      
      # UI UPDATE - STEP 1
      output$status <- renderText({
        paste0(
          "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n",
          "🔄 STEP 1: READING FILES\n",
          "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n",
          "✓ API Key: ", api_key_preview, "\n",
          "✓ Files to process: ", nrow(values$files), "\n",
          "✓ Timeout: ", if(use_timeout && !is.null(timeout_val)) paste(timeout_val, "sec") else "UNLIMITED", "\n\n",
          "Status: Reading files...\n"
        )
      })
      
      Sys.sleep(0.5)
      
      tryCatch({
        start_time <- Sys.time()
        
        cat("📖 Reading files...\n")
        flush.console()
        
        all_text <- character()
        for (i in 1:nrow(values$files)) {
          cat("   ", i, "/", nrow(values$files), ": ", values$files$filename[i], "\n", sep = "")
          flush.console()
          
          file_content <- paste(readLines(values$files$path[i], warn = FALSE, encoding = "UTF-8"), collapse = "\n")
          all_text <- c(all_text, paste0("\n=== ", values$files$filename[i], " ===\n"), file_content)
        }
        
        combined <- paste(all_text, collapse = "\n")
        values$concatenated <- combined
        
        word_count <- length(strsplit(combined, "\\s+")[[1]])
        char_count <- nchar(combined)
        
        cat("✅ All files read\n")
        cat("   Total words:", format(word_count, big.mark = ","), "\n")
        cat("   Total characters:", format(char_count, big.mark = ","), "\n\n")
        flush.console()
        
        # UI UPDATE - STEP 2
        output$status <- renderText({
          paste0(
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n",
            "📋 STEP 2: PREPARING REQUEST\n",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n",
            "✓ Files read: ", nrow(values$files), "\n",
            "✓ Total words: ", format(word_count, big.mark = ","), "\n",
            "✓ Total characters: ", format(char_count, big.mark = ","), "\n",
            "✓ Max summary words: ", input$maxWords, "\n\n",
            "Status: Building analysis request...\n"
          )
        })
        
        Sys.sleep(0.5)
        
        cat("📝 Building analysis request...\n")
        cat("   Prompt:", substr(input$prompt, 1, 50), "...\n")
        cat("   Max summary words:", input$maxWords, "\n\n")
        flush.console()
        
        messages <- list(
          list(role = "system", content = paste("You are a helpful assistant. Summarize the following text in approximately", input$maxWords, "words.")),
          list(role = "user", content = paste0(input$prompt, "\n\nCOMBINED TEXT FROM ", nrow(values$files), " FILES:\n\n", combined))
        )
        
        # UI UPDATE - STEP 3
        output$status <- renderText({
          paste0(
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n",
            "📤 STEP 3: SENDING TO CHATGPT\n",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n",
            "🚀 API CALL IN PROGRESS\n\n",
            "✓ Endpoint: api.openai.com/v1/chat/completions\n",
            "✓ Model: ", api_manager$chatgpt_model, "\n",
            "✓ API Key: ", api_key_preview, "\n",
            "✓ Input words: ", format(word_count, big.mark = ","), "\n",
            if(use_timeout && !is.null(timeout_val)) {
              paste0("✓ Timeout: ", timeout_val, " seconds\n")
            } else {
              "✓ Timeout: UNLIMITED (24 hours)\n"
            },
            "\n⏳ WAITING FOR ANALYSIS...\n",
            "   (This may take 10-90 seconds for large texts)\n\n",
            "🔴 DO NOT CLOSE THIS WINDOW\n"
          )
        })
        
        cat("📤 Sending to ChatGPT API...\n")
        if (use_timeout && !is.null(timeout_val)) {
          cat("   ⏱️  Timeout:", timeout_val, "seconds\n")
        } else {
          cat("   ♾️  No timeout (24 hour limit)\n")
        }
        flush.console()
        
        call_start <- Sys.time()
        
        # Make API call with proper timeout handling
        summary_text <- api_manager$chatgpt_complete(messages, use_timeout, timeout_val)
        
        call_end <- Sys.time()
        call_duration <- as.numeric(difftime(call_end, call_start, units = "secs"))
        
        cat("\n📥 Response received after", round(call_duration, 2), "seconds\n")
        flush.console()
        
        # UI UPDATE - STEP 4
        output$status <- renderText({
          paste0(
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n",
            "📥 STEP 4: RESPONSE RECEIVED\n",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n",
            "✅ Response received!\n",
            "⏱️  API call took: ", round(call_duration, 2), " seconds\n\n",
            "Status: Processing analysis...\n"
          )
        })
        
        Sys.sleep(0.5)
        
        summary_words <- length(strsplit(summary_text, "\\s+")[[1]])
        
        cat("✅ Analysis complete\n")
        cat("   Summary words:", format(summary_words, big.mark = ","), "\n")
        cat("   Summary characters:", format(nchar(summary_text), big.mark = ","), "\n")
        flush.console()
        
        updateTextAreaInput(session, "results", value = summary_text)
        values$summary <- summary_text
        
        total_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
        
        cat("\n", rep("=", 60), "\n", sep = "")
        cat("✅ BULK ANALYSIS COMPLETE\n")
        cat(rep("=", 60), "\n", sep = "")
        cat("Files processed:", nrow(values$files), "\n")
        cat("Input words:", format(word_count, big.mark = ","), "\n")
        cat("Summary words:", format(summary_words, big.mark = ","), "\n")
        cat("Total time:", round(total_time, 2), "seconds\n")
        cat("API call time:", round(call_duration, 2), "seconds\n")
        cat(rep("=", 60), "\n\n", sep = "")
        flush.console()
        
        # FINAL UI UPDATE
        output$status <- renderText({
          paste0(
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n",
            "✅ ✅ ✅ ANALYSIS COMPLETE! ✅ ✅ ✅\n",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n",
            "📊 ANALYSIS STATISTICS:\n\n",
            "Input:\n",
            "  • Files processed: ", nrow(values$files), "\n",
            "  • Total words: ", format(word_count, big.mark = ","), "\n",
            "  • Total characters: ", format(char_count, big.mark = ","), "\n\n",
            "Output:\n",
            "  • Summary words: ", format(summary_words, big.mark = ","), "\n",
            "  • Summary characters: ", format(nchar(summary_text), big.mark = ","), "\n\n",
            "Performance:\n",
            "  • Total time: ", round(total_time, 2), " seconds\n",
            "  • API time: ", round(call_duration, 2), " seconds\n\n",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n",
            "✓ Analysis displayed below\n",
            "✓ Ready to save\n"
          )
        })
        
        showNotification(
          paste("✅ Analysis complete!", summary_words, "words from", nrow(values$files), "files"), 
          type = "message", 
          duration = 5
        )
        
      }, error = function(e) {
        cat("\n", rep("=", 60), "\n", sep = "")
        cat("❌ ERROR DURING BULK ANALYSIS\n")
        cat(rep("=", 60), "\n", sep = "")
        cat("Error message:", e$message, "\n")
        cat("API Key set:", nchar(api_manager$chatgpt_api_key) > 0, "\n")
        cat("Files selected:", if(!is.null(values$files)) nrow(values$files) else 0, "\n")
        cat(rep("=", 60), "\n\n", sep = "")
        flush.console()
        
        output$status <- renderText({
          paste0(
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n",
            "❌ ERROR OCCURRED\n",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n",
            "Error: ", e$message, "\n\n",
            "TROUBLESHOOTING:\n\n",
            "1. Check R console for detailed error\n",
            "2. Verify ChatGPT API key in settings\n",
            "3. Test API connection in settings tab\n",
            "4. Check total text size (very large may fail)\n",
            "5. Try with fewer/smaller files\n",
            "6. Try enabling timeout (180+ seconds)\n"
          )
        })
        
        showNotification(
          paste("❌ Analysis failed:", substr(e$message, 1, 100)), 
          type = "error", 
          duration = 15
        )
      })
    })
    
    observeEvent(input$saveBtn, {
      req(values$summary)
      
      filename <- paste0("analysis_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")
      save_path <- file.path(values$save_dir, filename)
      
      tryCatch({
        writeLines(values$summary, save_path)
        cat("💾 Analysis saved to:", save_path, "\n\n")
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