# modules/Audio Transcription/summary.R
# Subtab: Transcription Summary

summary_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Step 1: Load Transcription", status = "primary", solidHeader = TRUE, width = 6,
          fileInput(ns("transcriptFile"), "Choose .txt file:", accept = ".txt"),
          verbatimTextOutput(ns("fileInfo")), br(),
          actionButton(ns("loadBtn"), "Load Transcription", class = "btn-info", style = "width: 100%;"),
          br(), br(), verbatimTextOutput(ns("loadedInfo"))),
      box(title = "Step 2: Configure Summary", status = "warning", solidHeader = TRUE, width = 6,
          textAreaInput(ns("instructions"), "Instructions:",
                        value = "Please provide a comprehensive summary of this conversation covering:\n1. Main topics discussed\n2. Key points and decisions made\n3. Action items or next steps\n4. Important questions or concerns raised",
                        height = "200px"),
          checkboxInput(ns("useTimeout"), "Enable timeout", value = FALSE),
          conditionalPanel(condition = sprintf("input['%s']", ns("useTimeout")),
                            numericInput(ns("timeout"), "Timeout (seconds):", value = 180, min = 30, max = 600)),
          br(),
          actionButton(ns("generateBtn"), "Generate Summary", class = "btn-success btn-lg", style = "width: 100%;"))
    ),
    fluidRow(
      box(title = "Generation Status", status = "info", solidHeader = TRUE, width = 12,
          verbatimTextOutput(ns("status")))
    ),
    fluidRow(
      box(title = "Generated Summary", status = "success", solidHeader = TRUE, width = 12,
          textAreaInput(ns("summary"), NULL, height = "500px", placeholder = "Summary will appear here..."),
          fluidRow(
            column(8, textInput(ns("savePath"), "Save directory:", placeholder = "Select directory...")),
            column(2, br(), shinyDirButton(ns("browseDir"), "Browse...", "Select Directory")),
            column(2, br(), actionButton(ns("saveBtn"), "Save", class = "btn-success", style = "width: 100%;"))
          ))
    )
  )
}

summary_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
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
      paste("File:", input$transcriptFile$name, "\nSize:", round(input$transcriptFile$size / 1024, 2), "KB")
    })

    observeEvent(input$loadBtn, {
      req(input$transcriptFile)
      tryCatch({
        text <- paste(readLines(input$transcriptFile$datapath, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
        values$transcript <- text
        word_count <- length(strsplit(text, "\\s+")[[1]])
        output$loadedInfo <- renderText(paste("✓ Loaded\nWords:", word_count, "\nChars:", nchar(text)))
        showNotification("Transcription loaded!", type = "message")
      }, error = function(e) {
        output$loadedInfo <- renderText(paste("❌ Error:", e$message))
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$generateBtn, {
      req(values$transcript)

      if (nchar(trimws(api_manager$chatgpt_api_key)) == 0) {
        output$status <- renderText("❌ ChatGPT API key not set\n\nPlease configure it in 'ChatGPT API Settings' tab")
        showNotification("Please set ChatGPT API key first", type = "error", duration = 10)
        return()
      }

      use_timeout <- isTRUE(input$useTimeout)
      timeout_val <- if (use_timeout && !is.null(input$timeout) && is.numeric(input$timeout) && input$timeout > 0) input$timeout else NULL

      word_count <- length(strsplit(values$transcript, "\\s+")[[1]])

      output$status <- renderText(paste0(
        "🔄 INITIALIZING\n\n✓ Model: ", api_manager$chatgpt_model, "\n",
        "✓ Words: ", format(word_count, big.mark = ","), "\n",
        "✓ Timeout: ", if (!is.null(timeout_val)) paste(timeout_val, "sec") else "UNLIMITED", "\n\n",
        "Status: Preparing request...\n"
      ))

      tryCatch({
        start_time <- Sys.time()
        output$status <- renderText(paste0(
          "📤 SENDING TO CHATGPT\n\n✓ Model: ", api_manager$chatgpt_model, "\n\n⏳ WAITING FOR RESPONSE...\n"
        ))

        full_prompt <- paste0(input$instructions, "\n\nTRANSCRIPTION TO SUMMARIZE:\n\n", values$transcript)
        summary_text <- api_manager$analyze_text(text = full_prompt, max_words = 2000, custom_prompt = NULL, timeout_seconds = timeout_val)

        summary_words <- length(strsplit(summary_text, "\\s+")[[1]])
        updateTextAreaInput(session, "summary", value = summary_text)
        values$summary <- summary_text

        total_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

        output$status <- renderText(paste0(
          "✅ ✅ ✅ SUCCESS! ✅ ✅ ✅\n\n",
          "Input words: ", format(word_count, big.mark = ","), "\n",
          "Summary words: ", format(summary_words, big.mark = ","), "\n",
          "Total time: ", round(total_time, 2), " seconds\n\n",
          "✓ Summary displayed below\n✓ Ready to save\n"
        ))

        showNotification(paste("✅ Summary complete:", summary_words, "words in", round(total_time, 1), "sec"), type = "message", duration = 5)

      }, error = function(e) {
        output$status <- renderText(paste0(
          "❌ ERROR OCCURRED\n\nError: ", e$message, "\n\n",
          "TROUBLESHOOTING:\n1. Verify ChatGPT API key in settings\n2. Test API connection in settings tab\n",
          "3. Check OpenAI account has credits\n4. Try with shorter transcript\n5. Try enabling timeout (180 seconds)\n"
        ))
        showNotification(paste("❌ Error:", substr(e$message, 1, 100)), type = "error", duration = 15)
      })
    })

    observeEvent(input$saveBtn, {
      req(values$summary)
      filename <- paste0("summary_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")
      save_path <- file.path(values$save_dir, filename)
      tryCatch({
        writeLines(values$summary, save_path)
        showNotification(paste("Saved to:", save_path), type = "message")
      }, error = function(e) {
        showNotification(paste("Error saving:", e$message), type = "error")
      })
    })

    output$status <- renderText("")
  })
}
