# modules/Audio Transcription/bulk_analysis.R
# Subtab: Bulk Text Analysis
#
# NOTE ON FIDELITY: the source app's server called api_manager$chatgpt_complete(),
# a method that doesn't exist anywhere in its own APIManager (only analyze_text()
# does) - calling this button would have thrown "could not find function" at
# runtime. This port calls api_manager$analyze_text() instead, with the same
# system/user prompt split the source intended.

bulk_analysis_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Step 1: Select Folder", status = "primary", solidHeader = TRUE, width = 6,
          fluidRow(
            column(8, textInput(ns("folderPath"), "Folder with .txt files:", placeholder = "Select folder...")),
            column(4, br(), shinyDirButton(ns("browseDir"), "Browse...", "Select Folder"))
          ),
          br(),
          actionButton(ns("scanBtn"), "Scan Folder", class = "btn-info", style = "width: 100%;"),
          br(), br(), uiOutput(ns("folderContents"))),
      box(title = "Step 2: Configure Analysis", status = "warning", solidHeader = TRUE, width = 6,
          selectInput(ns("sortMethod"), "Sort by:", choices = c("Filename" = "name", "Creation time" = "ctime", "Modified time" = "mtime")),
          numericInput(ns("maxWords"), "Max summary words:", value = 500, min = 50, max = 5000),
          checkboxInput(ns("useTimeout"), "Enable timeout", value = FALSE),
          conditionalPanel(condition = sprintf("input['%s']", ns("useTimeout")),
                            numericInput(ns("timeout"), "Timeout (seconds):", value = 180, min = 30, max = 600)),
          textInput(ns("prompt"), "Prompt:", value = "Summarize the following combined text:"),
          br(),
          actionButton(ns("analyzeBtn"), "Analyze & Summarize", class = "btn-success btn-lg", style = "width: 100%;"))
    ),
    fluidRow(
      box(title = "Analysis Status", status = "info", solidHeader = TRUE, width = 12,
          verbatimTextOutput(ns("status")))
    ),
    fluidRow(
      box(title = "Analysis Results", status = "success", solidHeader = TRUE, width = 12,
          textAreaInput(ns("results"), NULL, height = "400px", placeholder = "Results will appear here..."),
          fluidRow(
            column(8, textInput(ns("savePath"), "Save directory:", placeholder = "Select directory...")),
            column(2, br(), shinyDirButton(ns("browseSaveDir"), "Browse...", "Select Directory")),
            column(2, br(), actionButton(ns("saveBtn"), "Save", class = "btn-success", style = "width: 100%;"))
          ))
    )
  )
}

bulk_analysis_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    volumes <- get_volume_roots()
    shinyDirChoose(input, "browseDir", roots = volumes, session = session)
    shinyDirChoose(input, "browseSaveDir", roots = volumes, session = session)

    values <- reactiveValues(folder_dir = NULL, save_dir = getwd(), files = NULL, summary = "", concatenated = NULL)

    observeEvent(input$browseDir, {
      if (!is.integer(input$browseDir)) {
        selected <- parseDirPath(volumes, input$browseDir)
        if (length(selected) > 0) { values$folder_dir <- selected; updateTextInput(session, "folderPath", value = selected) }
      }
    })

    observeEvent(input$browseSaveDir, {
      if (!is.integer(input$browseSaveDir)) {
        selected <- parseDirPath(volumes, input$browseSaveDir)
        if (length(selected) > 0) { values$save_dir <- selected; updateTextInput(session, "savePath", value = selected) }
      }
    })

    observeEvent(input$scanBtn, {
      req(values$folder_dir)
      txt_files <- list.files(values$folder_dir, pattern = "\\.txt$", full.names = TRUE, ignore.case = TRUE)

      if (length(txt_files) == 0) {
        showNotification("No .txt files found in selected folder", type = "warning")
        return()
      }

      values$files <- data.frame(filename = basename(txt_files), path = txt_files, size = file.size(txt_files), stringsAsFactors = FALSE)

      output$folderContents <- renderUI({
        tagList(
          h5(paste("Found", length(txt_files), "text file(s)")),
          p(paste("Total size:", round(sum(values$files$size) / 1024, 2), "KB")),
          tags$ul(lapply(1:min(10, length(txt_files)), function(i) {
            tags$li(paste0(values$files$filename[i], " (", round(values$files$size[i] / 1024, 2), " KB)"))
          })),
          if (length(txt_files) > 10) p(paste("... and", length(txt_files) - 10, "more files"))
        )
      })

      showNotification(paste("Found", length(txt_files), "file(s)"), type = "message")
    })

    observeEvent(input$analyzeBtn, {
      req(values$files)

      if (nchar(trimws(api_manager$chatgpt_api_key)) == 0) {
        output$status <- renderText("❌ ChatGPT API key not set\n\nPlease configure it in 'ChatGPT API Settings' tab")
        showNotification("Please set ChatGPT API key first", type = "error", duration = 10)
        return()
      }

      use_timeout <- isTRUE(input$useTimeout)
      timeout_val <- if (use_timeout && !is.null(input$timeout) && is.numeric(input$timeout) && input$timeout > 0) input$timeout else NULL

      output$status <- renderText(paste0(
        "🔄 STEP 1: READING FILES\n\n✓ Files to process: ", nrow(values$files), "\n\nStatus: Reading files...\n"
      ))

      tryCatch({
        start_time <- Sys.time()
        all_text <- character()
        for (i in 1:nrow(values$files)) {
          file_content <- paste(readLines(values$files$path[i], warn = FALSE, encoding = "UTF-8"), collapse = "\n")
          all_text <- c(all_text, paste0("\n=== ", values$files$filename[i], " ===\n"), file_content)
        }
        combined <- paste(all_text, collapse = "\n")
        values$concatenated <- combined

        word_count <- length(strsplit(combined, "\\s+")[[1]])
        char_count <- nchar(combined)

        output$status <- renderText(paste0(
          "📋 STEP 2: PREPARING REQUEST\n\n✓ Files read: ", nrow(values$files), "\n",
          "✓ Total words: ", format(word_count, big.mark = ","), "\n",
          "✓ Max summary words: ", input$maxWords, "\n\nStatus: Building analysis request...\n"
        ))

        system_prompt <- paste("You are a helpful assistant. Summarize the following text in approximately", input$maxWords, "words.")
        user_content <- paste0(input$prompt, "\n\nCOMBINED TEXT FROM ", nrow(values$files), " FILES:\n\n", combined)

        output$status <- renderText(paste0(
          "📤 STEP 3: SENDING TO CHATGPT\n\n✓ Model: ", api_manager$chatgpt_model, "\n",
          "✓ Input words: ", format(word_count, big.mark = ","), "\n\n⏳ WAITING FOR ANALYSIS...\n"
        ))

        call_start <- Sys.time()
        summary_text <- api_manager$analyze_text(text = user_content, max_words = input$maxWords,
                                                   custom_prompt = system_prompt, timeout_seconds = timeout_val)
        call_duration <- as.numeric(difftime(Sys.time(), call_start, units = "secs"))

        summary_words <- length(strsplit(summary_text, "\\s+")[[1]])
        updateTextAreaInput(session, "results", value = summary_text)
        values$summary <- summary_text

        total_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

        output$status <- renderText(paste0(
          "✅ ✅ ✅ ANALYSIS COMPLETE! ✅ ✅ ✅\n\n",
          "Files processed: ", nrow(values$files), "\n",
          "Input words: ", format(word_count, big.mark = ","), "\n",
          "Summary words: ", format(summary_words, big.mark = ","), "\n\n",
          "Total time: ", round(total_time, 2), " seconds\n",
          "API time: ", round(call_duration, 2), " seconds\n\n",
          "✓ Analysis displayed below\n✓ Ready to save\n"
        ))

        showNotification(paste("✅ Analysis complete!", summary_words, "words from", nrow(values$files), "files"), type = "message", duration = 5)

      }, error = function(e) {
        output$status <- renderText(paste0(
          "❌ ERROR OCCURRED\n\nError: ", e$message, "\n\n",
          "TROUBLESHOOTING:\n1. Verify ChatGPT API key in settings\n2. Test API connection in settings tab\n",
          "3. Check total text size (very large may fail)\n4. Try with fewer/smaller files\n5. Try enabling timeout (180+ seconds)\n"
        ))
        showNotification(paste("❌ Analysis failed:", substr(e$message, 1, 100)), type = "error", duration = 15)
      })
    })

    observeEvent(input$saveBtn, {
      req(values$summary)
      filename <- paste0("analysis_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")
      save_path <- file.path(values$save_dir, filename)
      tryCatch({
        writeLines(values$summary, save_path)
        showNotification(paste("Saved to:", save_path), type = "message")
      }, error = function(e) {
        showNotification(paste("Error saving:", e$message), type = "error")
      })
    })

    output$status <- renderText("")
    output$folderContents <- renderUI({ NULL })
  })
}
