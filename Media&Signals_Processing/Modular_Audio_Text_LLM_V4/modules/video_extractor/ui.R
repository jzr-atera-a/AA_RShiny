video_extractor_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Select MP4 Video File",
        status = "primary",
        solidHeader = TRUE,
        width = 6,

        p("Select an MP4 file directly from disk (up to 500MB). This uses native Windows file browsing and does NOT upload the file through the browser, so it stays fast even for large videos."),

        shinyFilesButton(ns("selectFile"), "Browse for MP4 File...", "Select MP4 Video",
                          multiple = FALSE, icon = icon("file-video"),
                          style = "width: 100%;"),

        br(), br(),
        h5("File Information:"),
        verbatimTextOutput(ns("fileInfo"))
      ),

      box(
        title = "Output Settings",
        status = "info",
        solidHeader = TRUE,
        width = 6,

        fluidRow(
          column(8, textInput(ns("outputPath"), "Save MP3 chunks to:", placeholder = "Select directory...")),
          column(4, br(), shinyDirButton(ns("browseDir"), "Browse...", "Select Output Directory", style = "width: 100%;"))
        ),

        textInput(ns("outputPrefix"), "Output file prefix:", placeholder = "Leave empty to use video filename"),

        numericInput(ns("maxSizeMB"), "Maximum size per MP3 chunk (MB):", value = 10, min = 1, max = 24, step = 1),

        div(class = "info-box",
            style = "background:#eef1ff;border-radius:8px;padding:10px;margin-top:5px;",
            tags$strong("Note: "),
            "Whisper's API limit is 25MB per file. 10MB (default) keeps chunks safely under that, giving roughly 60-70 minutes of speech-quality audio per chunk."
        )
      )
    ),

    fluidRow(
      box(
        title = "Extract Audio",
        status = "success",
        solidHeader = TRUE,
        width = 12,

        actionButton(ns("extractBtn"), "Extract Audio to MP3 Chunks",
                     class = "btn-success btn-lg", style = "width: 100%;",
                     icon = icon("scissors")),
        br(), br(),
        verbatimTextOutput(ns("status"))
      )
    ),

    fluidRow(
      box(
        title = "Extracted Files",
        status = "warning",
        solidHeader = TRUE,
        width = 12,
        DTOutput(ns("resultsTable"))
      )
    )
  )
}
