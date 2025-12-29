bulk_analysis_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    # Setup volumes
    volumes <- getAppVolumes()
    shinyDirChoose(input, "browseBulkFolder", roots = volumes, session = session)
    shinyDirChoose(input, "browseSummaryDir", roots = volumes, session = session)
    shinyDirChoose(input, "browseConcatDir", roots = volumes, session = session)
    
    # Reactive values
    values <- reactiveValues(
      bulk_folder_dir = NULL,
      summary_output_dir = getwd(),
      concat_output_dir = getwd(),
      scanned_files = NULL,
      current_summary = "",
      folder_scanned = FALSE,
      concatenated_text = NULL
    )
    
    # Directory selections
    observeEvent(input$browseBulkFolder, {
      if (!is.null(input$browseBulkFolder) && !is.integer(input$browseBulkFolder)) {
        selected_path <- shinyFiles::parseDirPath(volumes, input$browseBulkFolder)
        if (length(selected_path) > 0) {
          values$bulk_folder_dir <- selected_path
          updateTextInput(session, "bulk_folder_path", value = selected_path)
          showNotification("Bulk analysis folder selected", type = "message")
        }
      }
    })
    
    observeEvent(input$browseSummaryDir, {
      if (!is.null(input$browseSummaryDir) && !is.integer(input$browseSummaryDir)) {
        selected_path <- shinyFiles::parseDirPath(volumes, input$browseSummaryDir)
        if (length(selected_path) > 0) {
          values$summary_output_dir <- selected_path
          updateTextInput(session, "summary_output_path", value = selected_path)
          showNotification("Summary save directory selected", type = "message")
        }
      }
    })
    
    observeEvent(input$browseConcatDir, {
      if (!is.null(input$browseConcatDir) && !is.integer(input$browseConcatDir)) {
        selected_path <- shinyFiles::parseDirPath(volumes, input$browseConcatDir)
        if (length(selected_path) > 0) {
          values$concat_output_dir <- selected_path
          updateTextInput(session, "concat_output_path", value = selected_path)
          showNotification("Concatenated text output directory selected", type = "message")
        }
      }
    })
    
    # Folder scanned status
    output$folderScanned <- reactive({
      return(values$folder_scanned)
    })
    outputOptions(output, "folderScanned", suspendWhenHidden = FALSE)
    
    # Scan folder for text files
    observeEvent(input$scanFolderBtn, {
      req(values$bulk_folder_dir)
      
      folder_path <- values$bulk_folder_dir
      if (!dir.exists(folder_path)) {
        showNotification("Selected folder does not exist", type = "error")
        return()
      }
      
      tryCatch({
        txt_files <- list.files(folder_path, pattern = "\\.txt$", full.names = TRUE, ignore.case = TRUE)
        
        if (length(txt_files) == 0) {
          showNotification("No .txt files found in the selected folder", type = "warning")
          values$folder_scanned <- FALSE
          values$scanned_files <- NULL
          return()
        }
        
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
    
    # Analyze button
    observeEvent(input$analyzeBtn, {
      req(values$scanned_files)
      
      if (is.null(api_manager$api_key) || nchar(trimws(api_manager$api_key)) == 0) {
        output$analysisStatus <- renderText("❌ Error: No API key found.")
        showNotification("Please set your API key in Settings first.", type = "error")
        return()
      }
      
      timeout_value <- input$bulkAnalysisTimeout %||% 180
      
      output$analysisStatus <- renderText(paste0(
        "🔄 Initializing analysis...\n",
        "⏱ Timeout set to: ", timeout_value, " seconds\n"
      ))
      
      tryCatch({
        start_time <- Sys.time()
        
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
        
        output$analysisStatus <- renderText("📖 Reading text files...\n")
        
        all_text <- character()
        for (i in 1:nrow(sorted_files)) {
          file_content <- readLines(sorted_files$path[i], warn = FALSE, encoding = "UTF-8")
          file_text <- paste(file_content, collapse = "\n")
          all_text <- c(all_text,
                        paste0("\n=== FILE: ", sorted_files$filename[i], " ===\n"),
                        file_text)
        }
        
        combined_text <- paste(all_text, collapse = "\n")
        word_count <- length(strsplit(combined_text, "\\s+")[[1]])
        
        output$analysisStatus <- renderText(paste0(
          "✓ Read ", nrow(sorted_files), " file(s)\n",
          "✓ Total words: ", word_count, "\n",
          "⏱ Using timeout: ", timeout_value, " seconds\n",
          "🤖 Sending to ChatGPT for analysis...\n"
        ))
        
        Sys.sleep(1)
        
        summary <- api_manager$analyze_text(
          combined_text,
          input$maxSummaryWords,
          input$analysisPrompt,
          timeout_value
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
    
    # Download concatenated text
    observeEvent(input$downloadConcatBtn, {
      req(values$scanned_files)
      
      output_dir <- values$concat_output_dir
      if (is.null(output_dir) || !dir.exists(output_dir)) {
        showNotification("Please select an output directory for the concatenated file.", type = "error")
        return()
      }
      
      tryCatch({
        showNotification("Preparing concatenated text...", type = "message")
        
        sorted_files <- values$scanned_files
        if (input$sortMethod == "name") {
          sorted_files <- sorted_files[order(sorted_files$filename), ]
        } else if (input$sortMethod == "ctime") {
          sorted_files <- sorted_files[order(sorted_files$ctime), ]
        } else if (input$sortMethod == "mtime") {
          sorted_files <- sorted_files[order(sorted_files$mtime, decreasing = TRUE), ]
        }
        
        all_text <- character()
        for (i in 1:nrow(sorted_files)) {
          file_content <- readLines(sorted_files$path[i], warn = FALSE, encoding = "UTF-8")
          file_text <- paste(file_content, collapse = "\n")
          all_text <- c(all_text,
                        paste0("\n=== FILE: ", sorted_files$filename[i], " ===\n"),
                        file_text)
        }
        
        combined_text <- paste(all_text, collapse = "\n")
        values$concatenated_text <- combined_text
        
        timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
        filename <- paste0("concatenated_text_", timestamp, ".txt")
        save_path <- file.path(output_dir, filename)
        
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
  })
}
