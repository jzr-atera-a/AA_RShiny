# ============================================================================
# Pure worker function - runs INSIDE the background process (future).
# Must not touch reactiveValues, input, output, or session - only plain
# R objects passed in as arguments, so it can be shipped to a separate
# R process and executed there without blocking the main Shiny session.
# ============================================================================
extract_mp4_to_mp3_worker <- function(input_path, output_dir, prefix, max_size_mb) {

  media_info <- av::av_media_info(input_path)
  duration <- media_info$duration

  if (is.null(duration) || is.na(duration) || duration <= 0) {
    stop("Could not determine video duration. File may be corrupt or have no audio track.")
  }

  if (is.null(max_size_mb) || is.na(max_size_mb) || max_size_mb <= 0) max_size_mb <- 10

  # --- Probe a short sample to measure the REAL mp3 encoding rate ---
  probe_duration <- min(30, duration)
  probe_file <- file.path(tempdir(), paste0("probe_", as.integer(Sys.time()), "_", sample(1000:9999, 1), ".mp3"))

  av::av_audio_convert(input_path, probe_file, format = "mp3",
                        start_time = 0, total_time = probe_duration)

  if (!file.exists(probe_file)) {
    stop("Probe extraction failed - could not read an audio stream from this MP4.")
  }

  probe_size <- file.info(probe_file)$size
  bytes_per_second <- probe_size / probe_duration
  file.remove(probe_file)

  # --- Calculate segment duration to hit the target chunk size ---
  max_size_bytes <- max_size_mb * 1024 * 1024 * 0.92  # 8% safety margin
  segment_duration <- max_size_bytes / bytes_per_second
  num_segments <- max(1, ceiling(duration / segment_duration))
  segment_duration <- duration / num_segments  # equalize across segments

  output_files <- character()
  output_sizes <- numeric()

  for (i in 1:num_segments) {
    start_time <- (i - 1) * segment_duration
    seg_time <- min(segment_duration, duration - start_time)

    filename <- if (num_segments == 1) {
      paste0(prefix, ".mp3")
    } else {
      paste0(prefix, "_part", sprintf("%02d", i), ".mp3")
    }
    filepath <- file.path(output_dir, filename)

    # Direct extraction from the source MP4 - no intermediate file written
    av::av_audio_convert(input_path, filepath, format = "mp3",
                          start_time = start_time, total_time = seg_time)

    if (file.exists(filepath)) {
      output_files <- c(output_files, filename)
      output_sizes <- c(output_sizes, round(file.info(filepath)$size / (1024^2), 2))
    }
  }

  data.frame(
    Segment = seq_along(output_files),
    Filename = output_files,
    `Size (MB)` = output_sizes,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

# ============================================================================
# Module server
# ============================================================================
video_extractor_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    volumes <- get_volume_roots()
    async_available <- requireNamespace("future", quietly = TRUE) &&
      requireNamespace("promises", quietly = TRUE)

    shinyFileChoose(input, "selectFile", roots = volumes, session = session,
                     filetypes = c("mp4", "MP4"))
    shinyDirChoose(input, "browseDir", roots = volumes, session = session)

    values <- reactiveValues(
      input_path = NULL,
      input_name = NULL,
      output_dir = getwd(),
      results = NULL,
      busy = FALSE
    )

    # --- Output directory selection ---
    observeEvent(input$browseDir, {
      if (!is.integer(input$browseDir)) {
        selected <- parseDirPath(volumes, input$browseDir)
        if (length(selected) > 0) {
          values$output_dir <- selected
          updateTextInput(session, "outputPath", value = selected)
        }
      }
    })

    # --- MP4 file selection (native Windows browser, no upload) ---
    observeEvent(input$selectFile, {
      if (!is.integer(input$selectFile)) {
        filepaths <- parseFilePaths(volumes, input$selectFile)
        if (nrow(filepaths) > 0) {
          values$input_path <- as.character(filepaths$datapath[1])
          values$input_name <- as.character(filepaths$name[1])

          size_mb <- round(file.info(values$input_path)$size / (1024^2), 2)

          info_text <- tryCatch({
            media_info <- av::av_media_info(values$input_path)
            dur_min <- round(media_info$duration / 60, 1)
            paste0(
              "File: ", values$input_name, "\n",
              "Size: ", size_mb, " MB\n",
              "Duration: ", dur_min, " minutes"
            )
          }, error = function(e) {
            paste0(
              "File: ", values$input_name, "\n",
              "Size: ", size_mb, " MB\n",
              "\u26a0 Could not read media info: ", e$message
            )
          })

          output$fileInfo <- renderText(info_text)
          values$results <- NULL
        }
      }
    })

    # --- Extraction (async - does not block the UI or other tabs) ---
    observeEvent(input$extractBtn, {
      req(values$input_path)

      if (isTRUE(values$busy)) {
        showNotification("An extraction is already running - please wait for it to finish.", type = "warning")
        return()
      }

      input_path  <- values$input_path
      output_dir  <- values$output_dir
      max_size_mb <- input$maxSizeMB
      prefix <- if (nchar(trimws(input$outputPrefix)) > 0) {
        input$outputPrefix
      } else {
        tools::file_path_sans_ext(values$input_name)
      }

      values$busy <- TRUE
      updateActionButton(session, "extractBtn", label = "Extracting... please wait")

      cat("\n", rep("=", 60), "\n", sep = "")
      cat("\U0001F3AC MP4 AUDIO EXTRACTION STARTED (background process)\n")
      cat(rep("=", 60), "\n", sep = "")
      cat("Source:", input_path, "\n")
      cat("Target chunk size:", max_size_mb, "MB\n")
      flush.console()

      if (async_available) {
        output$status <- renderText(paste0(
          "\U0001F504 Extracting in the background...\n",
          "The app remains fully responsive - you can switch tabs while this runs.\n\n",
          "Source: ", values$input_name
        ))

        prom <- promises::future_promise({
          extract_mp4_to_mp3_worker(input_path, output_dir, prefix, max_size_mb)
        }, seed = TRUE)

        prom %...>% (function(result) {
          values$results <- result
          values$busy <- FALSE
          updateActionButton(session, "extractBtn", label = "Extract Audio to MP3 Chunks")

          cat("\u2705 EXTRACTION COMPLETE:", nrow(result), "MP3 file(s) created\n")
          cat(rep("=", 60), "\n\n", sep = "")
          flush.console()

          output$status <- renderText(paste0(
            "\u2705 Complete! Created ", nrow(result), " MP3 chunk(s) in:\n",
            output_dir,
            "\n\nReady for transcription in the 'Audio Transcription' tab."
          ))

          showNotification(
            paste("\u2705 Extracted", nrow(result), "MP3 chunk(s)"),
            type = "message", duration = 6
          )
        }) %...!% (function(error) {
          values$busy <- FALSE
          updateActionButton(session, "extractBtn", label = "Extract Audio to MP3 Chunks")

          cat("\n\u274c ERROR:", error$message, "\n\n")
          flush.console()

          output$status <- renderText(paste0(
            "\u274c ERROR\n\n", error$message,
            "\n\nTROUBLESHOOTING:\n",
            "1. Ensure the 'av' package is installed (install.packages('av'))\n",
            "2. Verify the MP4 file is not corrupted\n",
            "3. Check the MP4 actually contains an audio track\n",
            "4. Ensure the output directory is writable\n"
          ))

          showNotification(
            paste("\u274c Extraction failed:", substr(error$message, 1, 100)),
            type = "error", duration = 15
          )
        })

        # Ensures unhandled promise rejections don't surface as generic
        # R errors outside the %...!% handler above.
        NULL

      } else {
        # Fallback: future/promises not installed - runs synchronously
        # (will block the UI, same as before) but still completes the task.
        output$status <- renderText("\U0001F504 Extracting (synchronous fallback - UI will be unresponsive)...")

        tryCatch({
          result <- extract_mp4_to_mp3_worker(input_path, output_dir, prefix, max_size_mb)
          values$results <- result
          values$busy <- FALSE
          updateActionButton(session, "extractBtn", label = "Extract Audio to MP3 Chunks")

          output$status <- renderText(paste0(
            "\u2705 Complete! Created ", nrow(result), " MP3 chunk(s) in:\n", output_dir
          ))
          showNotification(paste("\u2705 Extracted", nrow(result), "MP3 chunk(s)"), type = "message", duration = 6)

        }, error = function(e) {
          values$busy <- FALSE
          updateActionButton(session, "extractBtn", label = "Extract Audio to MP3 Chunks")
          output$status <- renderText(paste("\u274c ERROR:", e$message))
          showNotification(paste("\u274c Extraction failed:", substr(e$message, 1, 100)), type = "error", duration = 15)
        })
      }
    })

    output$resultsTable <- renderDT({
      req(values$results)
      datatable(values$results, options = list(dom = "t"), rownames = FALSE)
    })
  })
}
