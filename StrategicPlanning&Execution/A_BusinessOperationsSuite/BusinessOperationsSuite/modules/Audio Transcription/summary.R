# modules/Audio Transcription/summary.R
# Subtab: Transcription Summary
#
# The ChatGPT request runs in a separate step from the button click (see
# R/live_log.R), so the Generation Status box and the RStudio console show
# "sending / waiting" BEFORE the request starts, and the button is disabled
# until the summary comes back.

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
                           numericInput(ns("timeout"), "Timeout (seconds):", value = 300, min = 30, max = 1800)),
          br(),
          actionButton(ns("generateBtn"), "Generate Summary", class = "btn-success btn-lg", style = "width: 100%;"))
    ),
    fluidRow(
      box(title = "Generation Status", status = "info", solidHeader = TRUE, width = 12,
          live_log_output(ns("status"), height = "260px"))
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
    status <- create_live_log(session, "status", "[Summary]")
    job <- create_step_job(session)

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
        status$add(sprintf("📄 Loaded %s (%s words)", input$transcriptFile$name, format(word_count, big.mark = ",")))
        showNotification("Transcription loaded!", type = "message")
      }, error = function(e) {
        output$loadedInfo <- renderText(paste("❌ Error:", conditionMessage(e)))
        showNotification(paste("Error:", conditionMessage(e)), type = "error")
      })
    })

    observeEvent(input$generateBtn, {
      if (job$is_running()) {
        showNotification("Summary generation already in progress - please wait.", type = "warning", duration = 5)
        return()
      }
      if (is.null(values$transcript)) {
        showNotification("Load a transcription first (Step 1).", type = "warning")
        return()
      }

      status$clear()

      if (nchar(trimws(api_manager$chatgpt_api_key)) == 0) {
        status$add("❌ ChatGPT API key not set")
        status$add("   Go to API Settings > OpenAI API (Whisper + ChatGPT), enter the key and click 'Save API Key'.")
        showNotification("Please set the OpenAI API key first", type = "error", duration = 10)
        return()
      }

      s <- new.env()
      s$transcript <- values$transcript
      s$instructions <- input$instructions
      s$timeout <- if (isTRUE(input$useTimeout) && is.numeric(input$timeout) && !is.na(input$timeout) && input$timeout > 0) input$timeout else 900
      s$words <- length(strsplit(s$transcript, "\\s+")[[1]])
      s$t0 <- Sys.time()

      shinyjs::disable("generateBtn")
      status$add("🔄 STARTING SUMMARY GENERATION")
      status$add(sprintf("✓ Model: %s | Max tokens: %s | Temperature: %s",
                         api_manager$chatgpt_model, api_manager$chatgpt_max_tokens %||% "default",
                         api_manager$chatgpt_temperature %||% "default"))
      status$add(sprintf("✓ Transcript: %s words", format(s$words, big.mark = ",")))
      status$add(sprintf("✓ Timeout: %d sec", as.integer(s$timeout)))
      status$add("📤 Sending request to ChatGPT - waiting for response...")

      step <- function() {
        full_prompt <- paste0(s$instructions, "\n\nTRANSCRIPTION TO SUMMARIZE:\n\n", s$transcript)
        txt <- api_manager$analyze_text(text = full_prompt, max_words = 2000, custom_prompt = NULL,
                                        timeout_seconds = s$timeout, max_tokens = api_manager$chatgpt_max_tokens)
        if (is.null(txt) || !nzchar(trimws(txt))) stop("ChatGPT returned an empty response")
        s$summary <- txt
        TRUE
      }

      job$start(
        step_fn = step,
        on_error = function(e) {
          s$failed <- TRUE
          status$add("")
          status$add("❌ ERROR: ", conditionMessage(e))
          status$add("   Check the API key / credit, or tick 'Enable timeout' and allow more time.")
          showNotification(paste("❌ Error:", substr(conditionMessage(e), 1, 120)), type = "error", duration = 12)
        },
        on_done = function() {
          if (!isTRUE(s$failed)) {
            secs <- as.numeric(difftime(Sys.time(), s$t0, units = "secs"))
            sw <- length(strsplit(s$summary, "\\s+")[[1]])
            values$summary <- s$summary
            updateTextAreaInput(session, "summary", value = s$summary)
            status$add(sprintf("📥 Response received in %.1f sec", secs))
            status$add("═══════════════════════════════════════════")
            status$add(sprintf("✅ SUMMARY READY - %s words (from %s)", format(sw, big.mark = ","), format(s$words, big.mark = ",")))
            status$add("═══════════════════════════════════════════")
            showNotification(sprintf("✅ Summary complete: %d words in %.0f sec", sw, secs), type = "message", duration = 5)
          }
          shinyjs::enable("generateBtn")
        }
      )
    })

    observeEvent(input$saveBtn, {
      text <- input$summary %||% values$summary
      if (!nzchar(text)) {
        showNotification("Nothing to save yet.", type = "warning")
        return()
      }
      typed <- trimws(input$savePath %||% "")
      save_dir <- if (nzchar(typed)) typed else values$save_dir
      if (!dir.exists(save_dir)) dir.create(save_dir, recursive = TRUE, showWarnings = FALSE)
      save_path <- file.path(save_dir, paste0("summary_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt"))
      tryCatch({
        writeLines(text, save_path, useBytes = TRUE)
        status$add("💾 Saved: ", save_path)
        showNotification(paste("Saved to:", save_path), type = "message")
      }, error = function(e) {
        showNotification(paste("Error saving:", conditionMessage(e)), type = "error")
      })
    })
  })
}
