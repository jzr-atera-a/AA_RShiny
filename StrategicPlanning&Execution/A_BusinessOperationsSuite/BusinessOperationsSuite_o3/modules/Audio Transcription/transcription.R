# modules/Audio Transcription/transcription.R
# Subtab: Audio Transcription (Whisper, batch of up to 10 files)

transcription_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Audio Upload", status = "primary", solidHeader = TRUE, width = 6,
          fileInput(ns("audioFiles"), "Choose Audio Files (up to 10)", multiple = TRUE, accept = c(".mp3", ".m4a", ".flac", ".ogg")),
          verbatimTextOutput(ns("fileInfo")),
          h5("Settings:"),
          checkboxInput(ns("useTimeout"), "Enable timeout", value = FALSE),
          conditionalPanel(condition = sprintf("input['%s']", ns("useTimeout")),
                            numericInput(ns("timeout"), "Timeout (seconds):", value = 180, min = 30, max = 600)),
          br(),
          actionButton(ns("transcribeBtn"), "Transcribe", class = "btn-primary btn-lg", style = "width: 100%;")),
      box(title = "Processing Status", status = "info", solidHeader = TRUE, width = 6,
          verbatimTextOutput(ns("status")))
    ),
    fluidRow(
      box(title = "Transcription Results", status = "success", solidHeader = TRUE, width = 12,
          textAreaInput(ns("results"), NULL, height = "500px", placeholder = "Results will appear here..."),
          fluidRow(
            column(8, textInput(ns("savePath"), "Save directory:", placeholder = "Select directory...")),
            column(2, br(), shinyDirButton(ns("browseDir"), "Browse...", "Select Directory")),
            column(2, br(), actionButton(ns("saveBtn"), "Save", class = "btn-success", style = "width: 100%;"))
          ))
    )
  )
}

transcription_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
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
      paste("Files:", num, "\nTotal size:", round(sum(input$audioFiles$size) / 1024 / 1024, 2), "MB")
    })

    observeEvent(input$transcribeBtn, {
      req(input$audioFiles)

      if (nchar(trimws(api_manager$whisper_api_key)) == 0) {
        output$status <- renderText("❌ No Whisper API key set\n\nPlease configure it in 'Whisper API Settings' tab")
        showNotification("Please set Whisper API key first", type = "error", duration = 10)
        return()
      }

      num_files <- nrow(input$audioFiles)
      if (num_files > 10) {
        output$status <- renderText("❌ Max 10 files allowed")
        showNotification("Please select up to 10 files only", type = "error")
        return()
      }

      use_timeout <- isTRUE(input$useTimeout)
      timeout_val <- if (use_timeout && !is.null(input$timeout) && is.numeric(input$timeout) && input$timeout > 0) input$timeout else NULL

      output$status <- renderText(paste0(
        "🔄 INITIALIZING BATCH TRANSCRIPTION\n\n",
        "Files to process: ", num_files, "\n",
        "Timeout: ", if (!is.null(timeout_val)) paste(timeout_val, "sec") else "UNLIMITED", "\n\n",
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

          output$status <- renderText(paste0(
            "📤 PROCESSING FILE ", i, " of ", num_files, "\n\n",
            "File: ", file_name, "\nSize: ", file_size_mb, " MB\n\n",
            "  📤 Uploading to Whisper API...\n  ⏳ Waiting for transcription...\n"
          ))

          file_start <- Sys.time()
          transcription <- api_manager$transcribe_audio(file_path, use_timeout, timeout_val)
          file_time <- as.numeric(difftime(Sys.time(), file_start, units = "secs"))

          file_header <- paste0("\n\n=== FILE ", i, ": ", file_name, " ===\n\n")
          all_transcriptions <- c(all_transcriptions, paste0(file_header, transcription))
          combined <- paste(all_transcriptions, collapse = "\n")
          updateTextAreaInput(session, "results", value = combined)
          values$transcription <- combined

          file_words <- length(strsplit(trimws(transcription), "\\s+")[[1]])
          total_words <- total_words + file_words

          api_manager$add_transcription_record(filename = file_name, word_count = file_words,
                                                processing_time = round(file_time, 2), file_size = file_size_mb)

          output$status <- renderText(paste0(
            "✅ COMPLETED FILE ", i, " of ", num_files, "\n\n",
            "File: ", file_name, "\nWords: ", format(file_words, big.mark = ","), "\n",
            "Time: ", round(file_time, 2), " seconds\n\n",
            "Progress: ", i, " / ", num_files, " files - ", format(total_words, big.mark = ","), " words so far\n\n",
            if (i < num_files) "Proceeding to next file..." else "All files processed!"
          ))

          if (i < num_files) Sys.sleep(1)
        }

        total_time <- as.numeric(difftime(Sys.time(), overall_start, units = "secs"))

        output$status <- renderText(paste0(
          "✅ ✅ ✅ ALL TRANSCRIPTIONS COMPLETE! ✅ ✅ ✅\n\n",
          "Files processed: ", num_files, "\n",
          "Total words: ", format(total_words, big.mark = ","), "\n",
          "Total time: ", round(total_time, 2), " seconds\n",
          "Words per second: ", round(total_words / total_time, 1), "\n\n",
          "✓ Transcriptions ready in text area\n✓ Ready to save to file\n"
        ))

        showNotification(paste("✅ All", num_files, "files transcribed! Total:", total_words, "words"), type = "message", duration = 5)

      }, error = function(e) {
        output$status <- renderText(paste0(
          "❌ ERROR OCCURRED\n\nError: ", e$message, "\n\n",
          "Files completed before error: ", length(all_transcriptions), " of ", num_files, "\n\n",
          "TROUBLESHOOTING:\n1. Verify Whisper API key in settings\n2. Test API connection in settings tab\n",
          "3. Check file size (max 25 MB per file)\n4. Try with smaller files\n5. Try enabling timeout (180 seconds)\n"
        ))
        showNotification(paste("❌ Transcription failed:", substr(e$message, 1, 100)), type = "error", duration = 15)

        if (length(all_transcriptions) > 0) {
          combined <- paste(all_transcriptions, collapse = "\n")
          updateTextAreaInput(session, "results", value = combined)
          values$transcription <- combined
        }
      })
    })

    observeEvent(input$saveBtn, {
      req(values$transcription, input$audioFiles)

      num <- nrow(input$audioFiles)
      filename <- if (num == 1) paste0(tools::file_path_sans_ext(input$audioFiles$name[1]), ".txt")
                  else paste0("batch_transcription_", num, "files_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")
      save_path <- file.path(values$save_dir, filename)

      tryCatch({
        writeLines(values$transcription, save_path)
        showNotification(paste("Saved to:", save_path), type = "message")
      }, error = function(e) {
        showNotification(paste("Error saving:", e$message), type = "error")
      })
    })

    output$status <- renderText("")
  })
}
