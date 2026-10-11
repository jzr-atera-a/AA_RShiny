# modules/Audio Transcription/converter.R
# Subtab: Audio Converter & Splitter
# Converts M4A/MP3/WAV to MP3 and splits it into parts (by size or by count).
#
# Uses the av package (same as the working Modular_Audio_Text_LLM_V4 app).
# Each segment is encoded in its own step (see R/live_log.R), so the
# Processing Status and Console Log update live while the job runs and the
# app stays responsive between segments.

converter_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Audio File Upload", status = "primary", solidHeader = TRUE, width = 6,
          fileInput(ns("audioFile"), "Choose Audio File (M4A, MP3, WAV)",
                    accept = c(".m4a", ".mp3", ".wav")),
          verbatimTextOutput(ns("fileInfo")),
          h5("Output Settings:"),
          fluidRow(
            column(8, textInput(ns("outputPath"), "Save to directory:", placeholder = "Select directory...")),
            column(4, br(), shinyDirButton(ns("browseDir"), "Browse...", "Select Directory"))
          ),
          textInput(ns("outputPrefix"), "Output file prefix:", placeholder = "Leave empty for original name")),
      box(title = "Split Settings", status = "info", solidHeader = TRUE, width = 6,
          radioButtons(ns("splitMethod"), "Split Method:",
                       choices = list("By Number of Files" = "num_files", "By File Size" = "file_size"),
                       selected = "file_size"),
          conditionalPanel(condition = sprintf("input['%s'] == 'num_files'", ns("splitMethod")),
                           numericInput(ns("numSplits"), "Number of files:", value = 2, min = 1, max = 50)),
          conditionalPanel(condition = sprintf("input['%s'] == 'file_size'", ns("splitMethod")),
                           numericInput(ns("maxSizeMB"), "Maximum file size (MB):", value = 10, min = 1, max = 500)),
          br(),
          actionButton(ns("processBtn"), "Convert & Split Audio", class = "btn-success btn-lg", style = "width: 100%;"))
    ),
    fluidRow(
      box(title = "Live Console Output", status = "warning", solidHeader = TRUE, width = 12,
          tabsetPanel(
            tabPanel("Processing Status", br(), live_log_output(ns("status"))),
            tabPanel("Console Log", br(), live_log_output(ns("console")))
          ))
    ),
    fluidRow(
      box(title = "Results", status = "success", solidHeader = TRUE, width = 12,
          DTOutput(ns("resultsTable")))
    )
  )
}

converter_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    volumes <- get_volume_roots()
    shinyDirChoose(input, "browseDir", roots = volumes, session = session)

    values <- reactiveValues(output_dir = getwd(), results = NULL)
    status <- create_live_log(session, "status", "[Converter]")
    console <- create_live_log(session, "console", "[ffmpeg]")
    job <- create_step_job(session)

    observeEvent(input$browseDir, {
      if (!is.integer(input$browseDir)) {
        selected <- parseDirPath(volumes, input$browseDir)
        if (length(selected) > 0) {
          values$output_dir <- selected
          updateTextInput(session, "outputPath", value = selected)
        }
      }
    })

    output$fileInfo <- renderText({
      req(input$audioFile)
      paste("File:", input$audioFile$name, "\nSize:", round(input$audioFile$size / 1024 / 1024, 2), "MB")
    })

    # Encode one piece with av, capturing av's ffmpeg output so it can be shown
    # in the Console Log tab (header + last progress line, like RStudio shows).
    encode_piece <- function(input_path, out_path, start_time, total_time) {
      tf <- tempfile(fileext = ".log")
      con <- file(tf, open = "wt")
      sink(con, type = "message")
      res <- tryCatch({
        av::av_audio_convert(input_path, out_path, format = "mp3",
                             start_time = start_time, total_time = total_time, verbose = TRUE)
        NULL
      }, error = function(e) e, finally = {
        sink(type = "message")
        close(con)
      })
      ff <- tryCatch(readLines(tf, warn = FALSE), error = function(e) character())
      unlink(tf)
      list(error = res, log = ff)
    }

    show_ffmpeg <- function(ff_lines) {
      if (length(ff_lines) == 0) return()
      frames <- grepl("^Adding audio frame", ff_lines)
      header <- ff_lines[!frames & nzchar(trimws(ff_lines))]
      for (l in head(header, 8)) console$raw(l)
      if (any(frames)) {
        n <- sum(frames)
        console$raw(sprintf("  ... %s audio frames encoded ...", format(n, big.mark = ",")))
        console$raw(tail(ff_lines[frames], 1))
      }
      console$raw("")
    }

    resolve_output_dir <- function() {
      typed <- trimws(input$outputPath %||% "")
      dir <- if (nzchar(typed)) typed else values$output_dir
      if (!dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
      if (!dir.exists(dir)) stop("Output directory does not exist and could not be created: ", dir)
      normalizePath(dir, winslash = "/")
    }

    observeEvent(input$processBtn, {
      if (job$is_running()) {
        showNotification("Audio processing already in progress - please wait.", type = "warning", duration = 5)
        return()
      }
      if (is.null(input$audioFile)) {
        showNotification("Please choose an audio file first.", type = "warning")
        return()
      }

      status$clear()
      console$clear()
      values$results <- NULL

      out_dir <- tryCatch(resolve_output_dir(), error = function(e) { status$add("❌ ", conditionMessage(e)); NULL })
      if (is.null(out_dir)) return()

      # Snapshot of all settings for this job
      s <- new.env()
      s$input_path <- input$audioFile$datapath
      s$file_name  <- input$audioFile$name
      s$file_size  <- input$audioFile$size
      s$out_dir    <- out_dir
      s$method     <- input$splitMethod
      s$num_splits <- max(1, as.integer(input$numSplits %||% 2))
      s$max_mb     <- max(1, as.numeric(input$maxSizeMB %||% 10))
      s$prefix     <- if (nzchar(trimws(input$outputPrefix %||% ""))) trimws(input$outputPrefix) else tools::file_path_sans_ext(s$file_name)
      s$phase      <- "info"
      s$i          <- 0
      s$files      <- data.frame(Part = integer(), Filename = character(), Start = character(),
                                 End = character(), Size_MB = numeric(), Status = character(),
                                 stringsAsFactors = FALSE)
      s$t0         <- Sys.time()

      shinyjs::disable("processBtn")
      status$add("🔄 STARTING AUDIO CONVERSION")
      status$add(sprintf("📁 File: %s (%.2f MB)", s$file_name, s$file_size / 1048576))
      status$add(sprintf("📂 Output folder: %s", s$out_dir))
      status$add(if (s$method == "file_size") sprintf("✂️ Split method: by file size (max %.0f MB per file)", s$max_mb)
                 else sprintf("✂️ Split method: into %d files", s$num_splits))
      status$add("⏱️ Reading audio duration...")

      step <- function() {
        if (s$phase == "info") {
          info <- av::av_media_info(s$input_path)
          s$duration <- info$duration
          if (is.null(s$duration) || is.na(s$duration) || s$duration <= 0) stop("Could not read audio duration - is this a valid audio file?")
          status$add(sprintf("✓ Duration: %s (%.1f minutes)", fmt_hms(s$duration), s$duration / 60))

          if (s$method == "file_size") {
            status$add("🔬 Measuring MP3 output bitrate (encoding a 30-second sample)...")
            s$phase <- "probe"
          } else {
            s$n <- s$num_splits
            s$phase <- "plan"
          }
          return(FALSE)
        }

        if (s$phase == "probe") {
          probe_len <- min(30, s$duration)
          probe_file <- tempfile(fileext = ".mp3")
          r <- encode_piece(s$input_path, probe_file, 0, probe_len)
          if (!is.null(r$error) || !file.exists(probe_file)) stop("Test encode failed: ", conditionMessage(r$error %||% simpleError("no output")))
          bytes_per_sec <- file.size(probe_file) / probe_len
          unlink(probe_file)
          max_len <- (s$max_mb * 1048576 * 0.95) / bytes_per_sec
          s$n <- max(1, ceiling(s$duration / max_len))
          status$add(sprintf("✓ MP3 output rate: %.0f kbps → max %s per %.0f MB file", bytes_per_sec * 8 / 1000, fmt_hms(max_len), s$max_mb))
          s$phase <- "plan"
          return(FALSE)
        }

        if (s$phase == "plan") {
          s$seg_len <- s$duration / s$n
          status$add(sprintf("✓ Will create %d file(s) of ~%s each", s$n, fmt_hms(s$seg_len)))
          status$add("")
          s$i <- 1
          status$add(sprintf("⏳ [1/%d] Encoding part 1 (%s → %s)...", s$n, fmt_hms(0), fmt_hms(min(s$seg_len, s$duration))))
          s$phase <- "encode"
          return(FALSE)
        }

        if (s$phase == "encode") {
          i <- s$i
          start <- (i - 1) * s$seg_len
          end <- if (i == s$n) s$duration else i * s$seg_len
          fname <- if (s$n == 1) paste0(s$prefix, ".mp3") else paste0(s$prefix, "_part", sprintf("%02d", i), ".mp3")
          fpath <- file.path(s$out_dir, fname)

          t_seg <- Sys.time()
          r <- encode_piece(s$input_path, fpath, start, end - start)
          show_ffmpeg(r$log)
          if (!is.null(r$error)) stop(sprintf("Part %d failed: %s", i, conditionMessage(r$error)))
          if (!file.exists(fpath)) stop(sprintf("Part %d: output file was not created (%s)", i, fpath))

          size_mb <- file.size(fpath) / 1048576
          over <- s$method == "file_size" && size_mb > s$max_mb
          status$add(sprintf("   ✓ Saved %s (%.2f MB) in %.1f sec%s", fname, size_mb,
                             as.numeric(difftime(Sys.time(), t_seg, units = "secs")),
                             if (over) "  ⚠️ above size limit" else ""))

          s$files <- rbind(s$files, data.frame(Part = i, Filename = fname, Start = fmt_hms(start), End = fmt_hms(end),
                                               Size_MB = round(size_mb, 2), Status = if (over) "⚠️ Over limit" else "✓ Complete",
                                               stringsAsFactors = FALSE))
          values$results <- s$files   # results table fills in live

          if (i >= s$n) {
            s$phase <- "done"
            return(TRUE)
          }
          s$i <- i + 1
          next_start <- i * s$seg_len
          next_end <- if (s$i == s$n) s$duration else s$i * s$seg_len
          status$add(sprintf("⏳ [%d/%d] Encoding part %d (%s → %s)...", s$i, s$n, s$i, fmt_hms(next_start), fmt_hms(next_end)))
          return(FALSE)
        }
        TRUE
      }

      job$start(
        step_fn = step,
        on_error = function(e) {
          s$failed <- TRUE
          status$add("")
          status$add("❌ ERROR: ", conditionMessage(e))
          status$add("   Check the file is a valid audio file and the output folder is writable.")
          showNotification(paste("❌ Conversion failed:", substr(conditionMessage(e), 1, 120)), type = "error", duration = 10)
        },
        on_done = function() {
          if (!isTRUE(s$failed)) {
            status$add("")
            status$add("═══════════════════════════════════════════")
            status$add(sprintf("✅ DONE - created %d file(s) in %.1f sec", nrow(s$files),
                               as.numeric(difftime(Sys.time(), s$t0, units = "secs"))))
            status$add(sprintf("📂 %s", s$out_dir))
            status$add("═══════════════════════════════════════════")
            showNotification(sprintf("✅ Created %d audio file(s)", nrow(s$files)), type = "message", duration = 5)
          }
          shinyjs::enable("processBtn")
        }
      )
    })

    output$resultsTable <- renderDT({
      req(values$results)
      datatable(values$results, options = list(dom = "t", pageLength = 50), rownames = FALSE)
    })
  })
}
