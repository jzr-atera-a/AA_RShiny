# modules/Audio Transcription/converter.R
# Subtab: Audio Converter & Splitter

converter_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Audio File Upload", status = "primary", solidHeader = TRUE, width = 6,
          fileInput(ns("audioFile"), "Choose Audio File (M4A or MP3)", accept = c(".m4a", ".mp3")),
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
                            numericInput(ns("numSplits"), "Number of MP3 files:", value = 2, min = 1, max = 50)),
          conditionalPanel(condition = sprintf("input['%s'] == 'file_size'", ns("splitMethod")),
                            numericInput(ns("maxSizeMB"), "Maximum file size (MB):", value = 10, min = 1, max = 500)),
          br(),
          actionButton(ns("processBtn"), "Convert & Split Audio", class = "btn-success btn-lg", style = "width: 100%;"))
    ),
    fluidRow(
      box(title = "Processing Status", status = "warning", solidHeader = TRUE, width = 12,
          verbatimTextOutput(ns("status")))
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

    observeEvent(input$processBtn, {
      req(input$audioFile)

      tryCatch({
        input_path <- input$audioFile$datapath
        audio_info <- av::av_media_info(input_path)
        duration <- audio_info$duration

        num_segments <- if (input$splitMethod == "num_files") {
          input$numSplits
        } else {
          max_size_mb <- input$maxSizeMB
          bytes_per_second <- input$audioFile$size / duration
          max_duration <- (max_size_mb * 0.95 * 1024 * 1024) / bytes_per_second
          ceiling(duration / max_duration)
        }

        segment_duration <- duration / num_segments
        output_files <- character()
        prefix <- if (nchar(trimws(input$outputPrefix)) > 0) input$outputPrefix else tools::file_path_sans_ext(input$audioFile$name)

        for (i in 1:num_segments) {
          start_time <- (i - 1) * segment_duration
          end_time <- min(i * segment_duration, duration)
          filename <- if (num_segments == 1) paste0(prefix, ".mp3") else paste0(prefix, "_part", sprintf("%02d", i), ".mp3")
          filepath <- file.path(values$output_dir, filename)

          av::av_audio_convert(input_path, filepath, format = "mp3", start_time = start_time, total_time = end_time - start_time)
          if (file.exists(filepath)) output_files <- c(output_files, filename)
        }

        values$results <- data.frame(Segment = 1:num_segments, Filename = output_files, stringsAsFactors = FALSE)
        output$status <- renderText(paste("✅ Complete! Created", num_segments, "file(s)"))
      }, error = function(e) {
        output$status <- renderText(paste("❌ Error:", e$message))
      })
    })

    output$resultsTable <- renderDT({
      req(values$results)
      datatable(values$results, options = list(dom = 't'), rownames = FALSE)
    })
  })
}
