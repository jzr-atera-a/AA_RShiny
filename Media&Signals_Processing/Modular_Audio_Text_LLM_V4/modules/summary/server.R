summary_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    volumes <- get_volume_roots()
    shinyDirChoose(input, "browseDir", roots = volumes, session = session)
    
    values <- reactiveValues(save_dir = getwd(), transcript = NULL, summary = "")
    
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
      req(input$transcriptFile)
      paste("File:", input$transcriptFile$name, "\nSize:", round(input$transcriptFile$size/1024, 2), "KB")
    })
    
    observeEvent(input$loadBtn, {
      req(input$transcriptFile)
      
      cat("\n📂 Loading transcript file...\n")
      flush.console()
      
      tryCatch({
        text <- paste(readLines(input$transcriptFile$datapath, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
        values$transcript <- text
        
        char_count <- nchar(text)
        word_count <- length(strsplit(text, "\\s+")[[1]])
        
        cat("✅ Transcript loaded\n")
        cat("   Words:", word_count, "\n")
        cat("   Characters:", char_count, "\n\n")
        flush.console()
        
        output$loadedInfo <- renderText(paste("✓ Loaded\nWords:", word_count, "\nChars:", char_count))
        showNotification("Transcription loaded!", type = "message")
        
      }, error = function(e) {
        cat("❌ Error loading transcript:", e$message, "\n\n")
        flush.console()
        output$loadedInfo <- renderText(paste("❌ Error:", e$message))
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    observeEvent(input$generateBtn, {
      req(values$transcript)
      
      cat("\n", rep("=", 60), "\n", sep = "")
      cat("📝 SUMMARY GENERATION STARTED\n")
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
      
      # Check timeout checkbox
      use_timeout <- isTRUE(input$useTimeout)
      
      timeout_val <- NULL
      if (use_timeout) {
        if (!is.null(input$timeout) && is.numeric(input$timeout) && input$timeout > 0) {
          timeout_val <- input$timeout
        }
      }
      
      cat("Timeout checkbox:", use_timeout, "\n")
      cat("Timeout value:", if(is.null(timeout_val)) "NULL (unlimited)" else paste(timeout_val, "seconds"), "\n")
      cat(rep("=", 60), "\n\n", sep = "")
      flush.console()
      
      word_count <- length(strsplit(values$transcript, "\\s+")[[1]])
      char_count <- nchar(values$transcript)
      
      output$status <- renderText({
        paste0(
          "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n",
          "🔄 INITIALIZING\n",
          "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n",
          "✓ API Key: ", api_key_preview, "\n",
          "✓ Model: ", api_manager$chatgpt_model, "\n",
          "✓ Words: ", format(word_count, big.mark = ","), "\n",
          "✓ Timeout: ", if(use_timeout && !is.null(timeout_val)) paste(timeout_val, "sec") else "UNLIMITED", "\n\n",
          "Status: Preparing request...\n"
        )
      })
      
      Sys.sleep(0.5)
      
      tryCatch({
        start_time <- Sys.time()
        
        cat("📊 Transcript Info:\n")
        cat("   Words:", format(word_count, big.mark = ","), "\n")
        cat("   Characters:", format(char_count, big.mark = ","), "\n\n")
        flush.console()
        
        output$status <- renderText({
          paste0(
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n",
            "📤 SENDING TO CHATGPT\n",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n",
            "✓ Model: ", api_manager$chatgpt_model, "\n",
            "✓ API Key: ", api_key_preview, "\n",
            if(use_timeout && !is.null(timeout_val)) {
              paste0("✓ Timeout: ", timeout_val, " seconds\n")
            } else {
              "✓ Timeout: UNLIMITED\n"
            },
            "\n⏳ WAITING FOR RESPONSE...\n"
          )
        })
        
        cat("📤 Sending to ChatGPT API...\n")
        flush.console()
        
        call_start <- Sys.time()
        
        # FIXED: Use analyze_text instead of chatgpt_complete
        full_prompt <- paste0(input$instructions, "\n\nTRANSCRIPTION TO SUMMARIZE:\n\n", values$transcript)
        summary_text <- api_manager$analyze_text(
          text = full_prompt,
          max_words = 2000,  # Default max words
          custom_prompt = NULL,
          timeout_seconds = timeout_val
        )
        
        call_end <- Sys.time()
        elapsed <- as.numeric(difftime(call_end, call_start, units = "secs"))
        
        cat("\n📥 Response received after", round(elapsed, 2), "seconds\n")
        flush.console()
        
        summary_words <- length(strsplit(summary_text, "\\s+")[[1]])
        
        cat("✅ Summary extracted\n")
        cat("   Words:", format(summary_words, big.mark = ","), "\n")
        flush.console()
        
        # Update UI with summary
        updateTextAreaInput(session, "summary", value = summary_text)
        values$summary <- summary_text
        
        total_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
        
        cat("\n", rep("=", 60), "\n", sep = "")
        cat("✅ SUMMARY GENERATION COMPLETE\n")
        cat(rep("=", 60), "\n", sep = "")
        cat("Input words:", format(word_count, big.mark = ","), "\n")
        cat("Summary words:", format(summary_words, big.mark = ","), "\n")
        cat("Total time:", round(total_time, 2), "seconds\n")
        cat(rep("=", 60), "\n\n", sep = "")
        flush.console()
        
        output$status <- renderText({
          paste0(
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n",
            "✅ ✅ ✅ SUCCESS! ✅ ✅ ✅\n",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n",
            "📊 SUMMARY STATISTICS:\n\n",
            "Input:\n",
            "  • Words: ", format(word_count, big.mark = ","), "\n",
            "  • Characters: ", format(char_count, big.mark = ","), "\n\n",
            "Output:\n",
            "  • Words: ", format(summary_words, big.mark = ","), "\n",
            "  • Characters: ", format(nchar(summary_text), big.mark = ","), "\n\n",
            "Performance:\n",
            "  • Total time: ", round(total_time, 2), " seconds\n",
            "  • API time: ", round(elapsed, 2), " seconds\n\n",
            "✓ Summary displayed below\n",
            "✓ Ready to save\n"
          )
        })
        
        showNotification(
          paste("✅ Summary complete:", summary_words, "words in", round(total_time, 1), "sec"), 
          type = "message", 
          duration = 5
        )
        
      }, error = function(e) {
        cat("\n", rep("=", 60), "\n", sep = "")
        cat("❌ ERROR OCCURRED\n")
        cat(rep("=", 60), "\n", sep = "")
        cat("Error message:", e$message, "\n")
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
            "4. Check OpenAI account has credits\n",
            "5. Try with shorter transcript\n",
            "6. Try enabling timeout (180 seconds)\n"
          )
        })
        
        showNotification(
          paste("❌ Error:", substr(e$message, 1, 100)), 
          type = "error", 
          duration = 15
        )
      })
    })
    
    observeEvent(input$saveBtn, {
      req(values$summary)
      
      filename <- paste0("summary_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")
      save_path <- file.path(values$save_dir, filename)
      
      tryCatch({
        writeLines(values$summary, save_path)
        cat("💾 Summary saved to:", save_path, "\n\n")
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
