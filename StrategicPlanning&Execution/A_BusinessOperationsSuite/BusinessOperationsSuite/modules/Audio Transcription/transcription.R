# modules/Audio Transcription/transcription.R
# Subtab: Audio Transcription (Whisper, batch of up to 10 files)
#
# - Each file is sent to Whisper in its own step (see R/live_log.R), so the
#   Live Processing Log and the RStudio console update after every file and
#   the "now uploading file X" line is visible while Whisper is working.
# - The Transcribe button is disabled while a batch runs and further clicks
#   are rejected, so a batch can only run once at a time.
# - Each file is sent exactly once (see api_manager$transcribe_audio).

transcription_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Audio Upload", status = "primary", solidHeader = TRUE, width = 6,
          fileInput(ns("audioFiles"), "Choose Audio Files (up to 10)",
                    multiple = TRUE,
                    accept = c(".mp3", ".m4a", ".flac", ".ogg", ".wav", ".mp4", ".mpeg", ".mpga", ".webm")),
          verbatimTextOutput(ns("fileInfo")),
          h5("Processing Settings:"),
          checkboxInput(ns("useTimeout"), "Use custom timeout", value = FALSE),
          conditionalPanel(condition = sprintf("input['%s']", ns("useTimeout")),
                           numericInput(ns("timeout"), "Timeout (seconds):", value = 600, min = 60, max = 3600)),
          p(em("Leave unchecked for an automatic timeout (60 sec per MB, minimum 3 minutes)"),
            style = "color: #666; font-size: 11px;"),
          br(),
          actionButton(ns("transcribeBtn"), "Transcribe", class = "btn-primary btn-lg", style = "width: 100%;")),
      box(title = "Live Processing Log", status = "info", solidHeader = TRUE, width = 6,
          live_log_output(ns("status"), height = "330px"))
    ),
    fluidRow(
      box(title = "Transcription Results", status = "success", solidHeader = TRUE, width = 12,
          textAreaInput(ns("results"), NULL, height = "400px", placeholder = "Results will appear here..."),
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

    values <- reactiveValues(save_dir = getwd(), transcription = "", file_names = NULL)
    status <- create_live_log(session, "status", "[Whisper]")
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
      req(input$audioFiles)
      num <- nrow(input$audioFiles)
      total_size <- round(sum(input$audioFiles$size) / 1024 / 1024, 2)
      big <- input$audioFiles$name[input$audioFiles$size > 25 * 1048576]
      paste0("Files: ", num, "\nTotal size: ", total_size, " MB",
             if (num > 10) "\n⚠️ Maximum 10 files allowed" else "",
             if (length(big) > 0) paste0("\n⚠️ Over Whisper's 25 MB limit (split first): ", paste(big, collapse = ", ")) else "")
    })

    observeEvent(input$transcribeBtn, {
      # Only one batch at a time
      if (job$is_running()) {
        showNotification("Transcription already in progress - please wait for it to finish.", type = "warning", duration = 5)
        return()
      }
      if (is.null(input$audioFiles)) {
        showNotification("Please choose audio file(s) first.", type = "warning")
        return()
      }

      status$clear()

      if (is.null(api_manager) || nchar(trimws(api_manager$whisper_api_key)) == 0) {
        status$add("❌ Whisper API key not configured")
        status$add("   Go to API Settings > OpenAI API (Whisper + ChatGPT), enter the key and click 'Save API Key'.")
        showNotification("Please configure the OpenAI API key first", type = "error", duration = 10)
        return()
      }

      files <- input$audioFiles
      n <- nrow(files)
      if (n > 10) {
        status$add("❌ Too many files (max 10)")
        showNotification("Please select up to 10 files only", type = "error")
        return()
      }

      # Snapshot job settings
      s <- new.env()
      s$files <- files
      s$n <- n
      s$i <- 1
      s$texts <- character()
      s$total_words <- 0
      s$failed <- character()
      s$t0 <- Sys.time()
      s$use_timeout <- isTRUE(input$useTimeout)
      s$timeout <- if (s$use_timeout && is.numeric(input$timeout) && !is.na(input$timeout) && input$timeout > 0) input$timeout else NULL

      values$transcription <- ""
      values$file_names <- files$name
      updateTextAreaInput(session, "results", value = "")
      shinyjs::disable("transcribeBtn")

      status$add("🔄 STARTING BATCH TRANSCRIPTION")
      status$add(sprintf("Files: %d | Language: %s | Timeout: %s", n,
                         if (nchar(api_manager$whisper_language %||% "") > 0) api_manager$whisper_language else "auto",
                         if (!is.null(s$timeout)) paste(s$timeout, "sec (custom)") else "automatic"))
      status$add("")
      status$add(sprintf("⏳ [1/%d] Uploading %s (%.2f MB) to Whisper - waiting for transcript...",
                         n, files$name[1], files$size[1] / 1048576))

      step <- function() {
        i <- s$i
        name <- s$files$name[i]
        size_mb <- s$files$size[i] / 1048576
        t_file <- Sys.time()

        result <- tryCatch(
          api_manager$transcribe_audio(s$files$datapath[i], use_timeout = s$use_timeout,
                                       timeout_seconds = s$timeout, log = status$add),
          error = function(e) e
        )
        secs <- as.numeric(difftime(Sys.time(), t_file, units = "secs"))

        if (inherits(result, "error")) {
          s$failed <- c(s$failed, name)
          status$add(sprintf("   ❌ %s failed after %.1f sec: %s", name, secs, conditionMessage(result)))
        } else {
          words <- length(strsplit(trimws(result), "\\s+")[[1]])
          s$total_words <- s$total_words + words
          s$texts <- c(s$texts, sprintf("═══ FILE %d: %s ═══\n%s", i, name, result))
          combined <- paste(s$texts, collapse = "\n\n")
          values$transcription <- combined
          updateTextAreaInput(session, "results", value = combined)   # results appear file by file
          status$add(sprintf("   ✓ Done in %.1f sec - %s words", secs, format(words, big.mark = ",")))
          tryCatch(api_manager$add_transcription_record(name, words, secs, round(size_mb, 2)),
                   error = function(e) NULL)
        }

        if (i >= s$n) return(TRUE)
        s$i <- i + 1
        status$add(sprintf("⏳ [%d/%d] Uploading %s (%.2f MB) to Whisper - waiting for transcript...",
                           s$i, s$n, s$files$name[s$i], s$files$size[s$i] / 1048576))
        FALSE
      }

      job$start(
        step_fn = step,
        on_error = function(e) {
          status$add("❌ Unexpected error: ", conditionMessage(e))
        },
        on_done = function() {
          total <- as.numeric(difftime(Sys.time(), s$t0, units = "secs"))
          ok <- s$n - length(s$failed)
          status$add("")
          status$add("═══════════════════════════════════════════")
          status$add(sprintf("%s %d of %d file(s) transcribed - %s words in %.1f min",
                             if (length(s$failed) == 0) "✅" else "⚠️", ok, s$n,
                             format(s$total_words, big.mark = ","), total / 60))
          if (length(s$failed) > 0) status$add("   Failed: ", paste(s$failed, collapse = ", "))
          status$add("═══════════════════════════════════════════")
          showNotification(sprintf("%d of %d file(s) transcribed", ok, s$n),
                           type = if (length(s$failed) == 0) "message" else "warning", duration = 6)
          shinyjs::enable("transcribeBtn")
        }
      )
    })

    # Save results to file
    observeEvent(input$saveBtn, {
      if (!nzchar(values$transcription)) {
        showNotification("Nothing to save yet.", type = "warning")
        return()
      }
      typed <- trimws(input$savePath %||% "")
      save_dir <- if (nzchar(typed)) typed else values$save_dir
      if (!dir.exists(save_dir)) dir.create(save_dir, recursive = TRUE, showWarnings = FALSE)

      names <- values$file_names
      filename <- if (length(names) == 1) {
        paste0(tools::file_path_sans_ext(names[1]), ".txt")
      } else {
        paste0("transcription_batch_", length(names), "files_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")
      }
      save_path <- file.path(save_dir, filename)

      tryCatch({
        writeLines(input$results %||% values$transcription, save_path, useBytes = TRUE)
        showNotification(sprintf("✓ Saved to: %s", save_path), type = "message", duration = 6)
        status$add("💾 Saved: ", save_path)
      }, error = function(e) {
        showNotification(paste("Error saving file:", conditionMessage(e)), type = "error")
      })
    })
  })
}
