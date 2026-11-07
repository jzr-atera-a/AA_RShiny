# modules/Visual Media/pdf_merger.R
# Subtab: PDF Merger

pdf_merger_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "PDF Merger Configuration", status = "primary", solidHeader = TRUE, width = 12,
          h4("Select PDF Files to Merge"),
          p("Upload PDF files in the order you want them merged.", style = "color: #6c757d; font-style: italic;"),
          fluidRow(
            column(6,
                   fileInput(ns("merge_pdf1"), "PDF File 1:", accept = c(".pdf")),
                   fileInput(ns("merge_pdf3"), "PDF File 3:", accept = c(".pdf")),
                   fileInput(ns("merge_pdf5"), "PDF File 5:", accept = c(".pdf"))),
            column(6,
                   fileInput(ns("merge_pdf2"), "PDF File 2:", accept = c(".pdf")),
                   fileInput(ns("merge_pdf4"), "PDF File 4:", accept = c(".pdf")))
          ),
          hr(),
          fluidRow(
            column(6, h4("Output File"), textInput(ns("merge_filename"), "Output Filename:", placeholder = "merged_document.pdf", value = "merged_document.pdf")),
            column(6, h4("Output Directory"),
                   fluidRow(
                     column(9, div(class = "directory-display", textOutput(ns("selected_merge_dir")))),
                     column(3, br(), shinyDirButton(ns("merge_dir_select"), "Browse", "Select output directory", class = "btn-primary", style = "width: 100%;"))
                   ))
          ),
          br(),
          fluidRow(column(12, actionButton(ns("merge_pdfs"), "Merge PDFs", class = "btn-primary btn-lg", style = "width: 100%;"))))
    ),
    fluidRow(box(title = "Selected Files Summary", status = "info", solidHeader = TRUE, width = 12,
                 div(class = "info-box", verbatimTextOutput(ns("merge_summary"))))),
    fluidRow(box(title = "Merge Status", status = "info", solidHeader = TRUE, width = 12,
                 div(class = "info-box", verbatimTextOutput(ns("merge_status")))))
  )
}

pdf_merger_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    volumes <- get_volume_roots()
    shinyDirChoose(input, "merge_dir_select", roots = volumes, session = session, restrictions = system.file(package = "base"))

    values <- reactiveValues(merge_directory = NULL, merge_status_text = "Ready to merge PDFs. Select at least 2 files and output path, then click 'Merge PDFs'.")

    observe({
      if (!is.null(input$merge_dir_select) && !is.integer(input$merge_dir_select)) {
        tryCatch({
          selected_path <- parseDirPath(volumes, input$merge_dir_select)
          if (length(selected_path) > 0 && selected_path != "") {
            values$merge_directory <- as.character(selected_path)
            showNotification("Output directory selected successfully!", type = "message", duration = 2)
          }
        }, error = function(e) showNotification(paste("Error selecting directory:", e$message), type = "warning"))
      }
    })

    output$selected_merge_dir <- renderText({
      if (is.null(values$merge_directory) || length(values$merge_directory) == 0) "No directory selected - Click 'Browse' to select"
      else values$merge_directory
    })

    output$merge_summary <- renderText({
      files <- list(input$merge_pdf1, input$merge_pdf2, input$merge_pdf3, input$merge_pdf4, input$merge_pdf5)
      selected_files <- Filter(function(x) !is.null(x), files)

      if (length(selected_files) == 0) {
        "No PDF files selected for merging.\n\nPlease upload at least 2 PDF files in the order you want them merged."
      } else {
        summary_text <- paste0("Selected Files (", length(selected_files), "):\n\n")
        for (i in 1:length(selected_files)) {
          file_info <- selected_files[[i]]
          file_size <- round(file.size(file_info$datapath) / 1024 / 1024, 2)
          summary_text <- paste0(summary_text, i, ". ", file_info$name, " (", file_size, " MB)\n")
        }
        if (length(selected_files) < 2) summary_text <- paste0(summary_text, "\n⚠ Please select at least 2 files to merge.")
        summary_text
      }
    })

    observeEvent(input$merge_pdfs, {
      files <- list(input$merge_pdf1, input$merge_pdf2, input$merge_pdf3, input$merge_pdf4, input$merge_pdf5)
      selected_files <- Filter(function(x) !is.null(x), files)

      if (length(selected_files) < 2) {
        showNotification("Please select at least 2 PDF files to merge.", type = "warning", duration = 5)
        values$merge_status_text <- "❌ Error: At least 2 PDF files are required for merging."
        return()
      }
      if (is.null(values$merge_directory) || length(values$merge_directory) == 0 || values$merge_directory == "") {
        showNotification("Please select an output directory first.", type = "warning", duration = 5)
        values$merge_status_text <- "❌ Error: No output directory selected. Click 'Browse' to select one."
        return()
      }
      if (is.null(input$merge_filename) || input$merge_filename == "" || trimws(input$merge_filename) == "") {
        showNotification("Please specify an output filename.", type = "warning", duration = 5)
        values$merge_status_text <- "❌ Error: No output filename specified."
        return()
      }

      showNotification("Merging PDFs... This may take a while for large files.", type = "message", duration = NULL, id = "processing_merge")
      values$merge_status_text <- paste0("Processing ", length(selected_files), " PDF files...")

      tryCatch({
        file_paths <- sapply(selected_files, function(x) x$datapath)
        for (i in 1:length(file_paths)) {
          if (!file.exists(file_paths[i])) stop(paste("File", i, "does not exist or cannot be accessed"))
        }

        output_filename <- trimws(input$merge_filename)
        if (!grepl("\\.pdf$", output_filename, ignore.case = TRUE)) output_filename <- paste0(output_filename, ".pdf")
        output_path <- file.path(values$merge_directory, output_filename)

        if (!dir.exists(values$merge_directory)) dir.create(values$merge_directory, recursive = TRUE)
        if (file.exists(output_path)) showNotification("Warning: Output file already exists and will be overwritten.", type = "warning", duration = 3)

        qpdf::pdf_combine(input = file_paths, output = output_path)

        if (!file.exists(output_path)) stop("Merge appeared to complete but output file was not created")

        output_size <- round(file.size(output_path) / 1024 / 1024, 2)
        removeNotification("processing_merge")

        values$merge_status_text <- paste0("✅ Successfully merged ", length(selected_files), " PDF files!\n\n",
                                           "Output: ", basename(output_path), " (", output_size, " MB)\nLocation: ", values$merge_directory)

        showNotification(paste("PDFs successfully merged into:", basename(output_path)), type = "message", duration = 5)
      }, error = function(e) {
        removeNotification("processing_merge")
        values$merge_status_text <- paste0("❌ Error merging PDFs:\n", e$message)
        showNotification(paste("Error merging PDFs:", e$message), type = "error", duration = 10)
      })
    })

    output$merge_status <- renderText({ values$merge_status_text })
  })
}
