# modules/Audio Transcription/video_extractor.R
# Subtab: Video Audio Extractor
# Uses native OS file/directory browsing (shinyFiles) instead of browser
# upload, so it stays fast for large videos (up to 500MB) - this means the
# Shiny process needs direct filesystem access (local/desktop execution,
# see README). Extraction runs in a background process (future/promises)
# when available, so it never blocks the rest of the app.

video_extractor_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Select MP4 Video File", status = "primary", solidHeader = TRUE, width = 6,
          p("Select an MP4 file directly from disk (up to 500MB). This uses native file browsing and does NOT upload the file through the browser, so it stays fast even for large videos."),
          shinyFilesButton(ns("selectFile"), "Browse for MP4 File...", "Select MP4 Video",
                            multiple = FALSE, icon = icon("file-video"), style = "width: 100%;"),
          br(), br(), h5("File Information:"), verbatimTextOutput(ns("fileInfo"))),
      box(title = "Output Settings", status = "info", solidHeader = TRUE, width = 6,
          fluidRow(
            column(8, textInput(ns("outputPath"), "Save MP3 chunks to:", placeholder = "Select directory...")),
            column(4, br(), shinyDirButton(ns("browseDir"), "Browse...", "Select Output Directory", style = "width: 100%;"))
          ),
          textInput(ns("outputPrefix"), "Output file prefix:", placeholder = "Leave empty to use video filename"),
          numericInput(ns("maxSizeMB"), "Maximum size per MP3 chunk (MB):", value = 10, min = 1, max = 24, step = 1),
          div(class = "info-box", style = "background:#eef1ff;border-radius:8px;padding:10px;margin-top:5px;",
              tags$strong("Note: "),
              "Whisper's API limit is 25MB per file. 10MB (default) keeps chunks safely under that, giving roughly 60-70 minutes of speech-quality audio per chunk."))
    ),
    fluidRow(
      box(title = "Extract Audio", status = "success", solidHeader = TRUE, width = 12,
          actionButton(ns("extractBtn"), "Extract Audio to MP3 Chunks", class = "btn-success btn-lg",
                       style = "width: 100%;", icon = icon("scissors")),
          br(), br(), verbatimTextOutput(ns("status")))
    ),
    fluidRow(
      box(title = "Extracted Files", status = "warning", solidHeader = TRUE, width = 12,
          DTOutput(ns("resultsTable")))
    )
  )
}

# Pure worker function - runs INSIDE the background process (future). Must
# not touch reactiveValues, input, output, or session - only plain R objects
# passed in as arguments, so it can be shipped to a separate R process.
extract_mp4_to_mp3_worker <- function(input_path, output_dir, prefix, max_size_mb) {
  media_info <- av::av_media_info(input_path)
  duration <- media_info$duration

  if (is.null(duration) || is.na(duration) || duration <= 0) {
    stop("Could not determine video duration. File may be corrupt or have no audio track.")
  }
  if (is.null(max_size_mb) || is.na(max_size_mb) || max_size_mb <= 0) max_size_mb <- 10

  probe_duration <- min(30, duration)
  probe_file <- file.path(tempdir(), paste0("probe_", as.integer(Sys.time()), "_", sample(1000:9999, 1), ".mp3"))
  av::av_audio_convert(input_path, probe_file, format = "mp3", start_time = 0, total_time = probe_duration, verbose = FALSE)
  if (!file.exists(probe_file)) stop("Probe extraction failed - could not read an audio stream from this MP4.")

  probe_size <- file.info(probe_file)$size
  bytes_per_second <- probe_size / probe_duration
  file.remove(probe_file)

  max_size_bytes <- max_size_mb * 1024 * 1024 * 0.92
  segment_duration <- max_size_bytes / bytes_per_second
  num_segments <- max(1, ceiling(duration / segment_duration))
  segment_duration <- duration / num_segments

  output_files <- character()
  output_sizes <- numeric()

  for (i in 1:num_segments) {
    start_time <- (i - 1) * segment_duration
    seg_time <- min(segment_duration, duration - start_time)
    filename <- if (num_segments == 1) paste0(prefix, ".mp3") else paste0(prefix, "_part", sprintf("%02d", i), ".mp3")
    filepath <- file.path(output_dir, filename)

    av::av_audio_convert(input_path, filepath, format = "mp3", start_time = start_time, total_time = seg_time, verbose = FALSE)

    if (file.exists(filepath)) {
      output_files <- c(output_files, filename)
      output_sizes <- c(output_sizes, round(file.info(filepath)$size / (1024^2), 2))
    }
  }

  data.frame(Segment = seq_along(output_files), Filename = output_files, `Size (MB)` = output_sizes,
             check.names = FALSE, stringsAsFactors = FALSE)
}

video_extractor_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    volumes <- get_volume_roots()
    async_available <- requireNamespace("future", quietly = TRUE) && requireNamespace("promises", quietly = TRUE)

    shinyFileChoose(input, "selectFile", roots = volumes, session = session, filetypes = c("mp4", "MP4"))
    shinyDirChoose(input, "browseDir", roots = volumes, session = session)

    values <- reactiveValues(input_path = NULL, input_name = NULL, output_dir = getwd(), results = NULL, busy = FALSE)

    observeEvent(input$browseDir, {
      if (!is.integer(input$browseDir)) {
        selected <- parseDirPath(volumes, input$browseDir)
        if (length(selected) > 0) {
          values$output_dir <- selected
          updateTextInput(session, "outputPath", value = selected)
        }
      }
    })

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
            paste0("File: ", values$input_name, "\nSize: ", size_mb, " MB\nDuration: ", dur_min, " minutes")
          }, error = function(e) {
            paste0("File: ", values$input_name, "\nSize: ", size_mb, " MB\n\u26a0 Could not read media info: ", e$message)
          })

          output$fileInfo <- renderText(info_text)
          values$results <- NULL
        }
      }
    })

    observeEvent(input$extractBtn, {
      req(values$input_path)
      if (isTRUE(values$busy)) {
        showNotification("An extraction is already running - please wait for it to finish.", type = "warning")
        return()
      }

      input_path <- values$input_path
      output_dir <- values$output_dir
      max_size_mb <- input$maxSizeMB
      prefix <- if (nchar(trimws(input$outputPrefix)) > 0) input$outputPrefix else tools::file_path_sans_ext(values$input_name)

      values$busy <- TRUE
      updateActionButton(session, "extractBtn", label = "Extracting... please wait")

      if (async_available) {
        output$status <- renderText(paste0(
          "\U0001F504 Extracting in the background...\n",
          "The app remains fully responsive - you can switch tabs while this runs.\n\n",
          "Source: ", values$input_name
        ))

        prom <- promises::future_promise({
          extract_mp4_to_mp3_worker(input_path, output_dir, prefix, max_size_mb)
        }, seed = TRUE, stdout = FALSE)

        prom %...>% (function(result) {
          values$results <- result
          values$busy <- FALSE
          updateActionButton(session, "extractBtn", label = "Extract Audio to MP3 Chunks")
          output$status <- renderText(paste0(
            "\u2705 Complete! Created ", nrow(result), " MP3 chunk(s) in:\n", output_dir,
            "\n\nReady for transcription in the 'Audio Transcription' tab."
          ))
          showNotification(paste("\u2705 Extracted", nrow(result), "MP3 chunk(s)"), type = "message", duration = 6)
        }) %...!% (function(error) {
          values$busy <- FALSE
          updateActionButton(session, "extractBtn", label = "Extract Audio to MP3 Chunks")
          output$status <- renderText(paste0(
            "\u274c ERROR\n\n", error$message,
            "\n\nTROUBLESHOOTING:\n1. Ensure the 'av' package is installed\n",
            "2. Verify the MP4 file is not corrupted\n3. Check the MP4 actually contains an audio track\n",
            "4. Ensure the output directory is writable\n"
          ))
          showNotification(paste("\u274c Extraction failed:", substr(error$message, 1, 100)), type = "error", duration = 15)
        })
        NULL

      } else {
        output$status <- renderText("\U0001F504 Extracting (synchronous fallback - UI will be unresponsive)...")
        tryCatch({
          result <- extract_mp4_to_mp3_worker(input_path, output_dir, prefix, max_size_mb)
          values$results <- result
          values$busy <- FALSE
          updateActionButton(session, "extractBtn", label = "Extract Audio to MP3 Chunks")
          output$status <- renderText(paste0("\u2705 Complete! Created ", nrow(result), " MP3 chunk(s) in:\n", output_dir))
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
