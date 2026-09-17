# modules/Visual Media/pdf_splitter.R
# Subtab: PDF Splitter
# Ported from a monolithic single-scope app.R into a proper namespaced module.

pdf_splitter_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "PDF Splitter Configuration", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(6, h4("Input PDF File"), fileInput(ns("input_pdf"), "Select PDF File:", accept = c(".pdf"), placeholder = "No file selected")),
            column(6, h4("Split Configuration"), numericInput(ns("num_parts"), "Number of Parts:", value = 2, min = 2, max = 20, step = 1))
          ),
          fluidRow(column(12, h4("Output Directory"),
                          fluidRow(
                            column(9, div(class = "directory-display", textOutput(ns("selected_output_dir")))),
                            column(3, shinyDirButton(ns("output_dir_select"), "Browse", "Select output directory", class = "btn-primary", style = "width: 100%;"))
                          ))),
          hr(),
          fluidRow(
            column(6, actionButton(ns("analyze_pdf"), "Analyze PDF", class = "btn-primary btn-lg", style = "width: 100%;")),
            column(6, actionButton(ns("split_pdf"), "Split PDF", class = "btn-primary btn-lg", style = "width: 100%;"))
          ))
    ),
    fluidRow(box(title = "PDF Analysis Results", status = "info", solidHeader = TRUE, width = 12,
                 div(class = "info-box", verbatimTextOutput(ns("pdf_info"))))),
    fluidRow(box(title = "Split Preview", status = "info", solidHeader = TRUE, width = 12,
                 div(class = "info-box", verbatimTextOutput(ns("split_preview")))))
  )
}

pdf_splitter_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    volumes <- get_volume_roots()
    shinyDirChoose(input, "output_dir_select", roots = volumes, session = session, restrictions = system.file(package = "base"))

    values <- reactiveValues(pdf_pages = NULL, pdf_name = NULL, split_plan = NULL, output_directory = NULL)

    observe({
      if (!is.null(input$output_dir_select) && !is.integer(input$output_dir_select)) {
        tryCatch({
          selected_path <- parseDirPath(volumes, input$output_dir_select)
          if (length(selected_path) > 0 && selected_path != "") {
            values$output_directory <- as.character(selected_path)
            showNotification("Output directory selected successfully!", type = "message", duration = 2)
          }
        }, error = function(e) showNotification(paste("Error selecting directory:", e$message), type = "warning"))
      }
    })

    output$selected_output_dir <- renderText({
      if (is.null(values$output_directory) || length(values$output_directory) == 0) "No directory selected - Click 'Browse' to select"
      else values$output_directory
    })

    observeEvent(input$analyze_pdf, {
      req(input$input_pdf)
      showNotification("Analyzing PDF... Please wait.", type = "message", duration = NULL, id = "analyzing_pdf")

      values$pdf_pages <- NULL; values$pdf_name <- NULL; values$split_plan <- NULL

      tryCatch({
        pdf_path <- input$input_pdf$datapath
        if (!file.exists(pdf_path)) stop("PDF file does not exist at the specified path")
        file_size <- file.size(pdf_path)
        if (is.na(file_size) || file_size == 0) stop("PDF file is empty or cannot be read")

        pdf_pages_count <- NULL
        tryCatch({
          pdf_pages_count <- pdftools::pdf_length(pdf_path)
          if (!is.null(pdf_pages_count) && length(pdf_pages_count) > 0 && !is.na(pdf_pages_count) && pdf_pages_count > 0) {
            values$pdf_pages <- pdf_pages_count
          } else pdf_pages_count <- NULL
        }, error = function(e1) pdf_pages_count <- NULL)

        if (is.null(pdf_pages_count)) {
          tryCatch({
            pdf_info_result <- pdftools::pdf_info(pdf_path)
            if (!is.null(pdf_info_result) && is.data.frame(pdf_info_result) && nrow(pdf_info_result) > 0) {
              values$pdf_pages <- nrow(pdf_info_result)
            } else stop("PDF info returned empty results")
          }, error = function(e2) stop("Unable to analyze PDF - file may be corrupted, password protected, or in an unsupported format"))
        }

        if (is.null(values$pdf_pages) || length(values$pdf_pages) == 0 || is.na(values$pdf_pages) || values$pdf_pages <= 0) {
          stop("Could not determine valid page count for PDF")
        }

        values$pdf_name <- tools::file_path_sans_ext(input$input_pdf$name)
        if (is.null(values$pdf_name) || length(values$pdf_name) == 0 || values$pdf_name == "") {
          values$pdf_name <- paste0("document_", format(Sys.time(), "%Y%m%d_%H%M%S"))
        }

        total_pages <- as.numeric(values$pdf_pages)
        num_parts <- as.numeric(input$num_parts)

        if (total_pages < num_parts) {
          showNotification(paste("Warning: PDF has only", total_pages, "pages but you requested", num_parts, "parts. Adjusting to", total_pages, "parts."), type = "warning")
          num_parts <- total_pages
        }

        pages_per_part <- ceiling(total_pages / num_parts)
        split_plan <- data.frame(Part = 1:num_parts, Start_Page = numeric(num_parts), End_Page = numeric(num_parts), Pages_Count = numeric(num_parts), stringsAsFactors = FALSE)

        for (i in 1:num_parts) {
          start_page <- (i - 1) * pages_per_part + 1
          end_page <- min(i * pages_per_part, total_pages)
          split_plan$Start_Page[i] <- start_page
          split_plan$End_Page[i] <- end_page
          split_plan$Pages_Count[i] <- end_page - start_page + 1
        }

        values$split_plan <- split_plan

        removeNotification("analyzing_pdf")
        showNotification(paste("PDF analysis completed! Found", total_pages, "pages."), type = "message")
      }, error = function(e) {
        values$pdf_pages <- NULL; values$pdf_name <- NULL; values$split_plan <- NULL
        removeNotification("analyzing_pdf")
        error_msg <- as.character(e$message)
        if (length(error_msg) == 0 || error_msg == "") error_msg <- "Unknown error occurred while analyzing PDF"
        showNotification(paste("Error analyzing PDF:", error_msg), type = "error", duration = 10)
      })
    })

    output$pdf_info <- renderText({
      if (is.null(values$pdf_pages)) "No PDF analyzed yet. Please select a PDF file and click 'Analyze PDF'."
      else paste0("PDF File: ", input$input_pdf$name, "\nTotal Pages: ", values$pdf_pages, "\nRequested Parts: ", input$num_parts)
    })

    output$split_preview <- renderText({
      if (is.null(values$split_plan)) {
        "Analysis required before preview."
      } else {
        preview_text <- "Split Plan:\n\n"
        for (i in 1:nrow(values$split_plan)) {
          part_name <- paste0(values$pdf_name, "_part", i, ".pdf")
          preview_text <- paste0(preview_text, "Part ", i, ": ", part_name, "\n",
                                 "  Pages: ", values$split_plan$Start_Page[i], " to ", values$split_plan$End_Page[i],
                                 " (", values$split_plan$Pages_Count[i], " pages)\n\n")
        }
        preview_text
      }
    })

    observeEvent(input$split_pdf, {
      req(input$input_pdf, values$split_plan)

      if (is.null(values$output_directory) || length(values$output_directory) == 0 || values$output_directory == "") {
        showNotification("Please select an output directory first.", type = "warning")
        return()
      }

      showNotification("Processing PDF... This may take a while for large files.", type = "message", duration = NULL, id = "processing_split")

      tryCatch({
        pdf_path <- input$input_pdf$datapath
        output_dir <- values$output_directory
        if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

        valid_parts <- which(!is.na(values$split_plan$Start_Page))

        for (i in valid_parts) {
          start_page <- values$split_plan$Start_Page[i]
          end_page <- values$split_plan$End_Page[i]
          output_file <- file.path(output_dir, paste0(values$pdf_name, "_part", i, ".pdf"))

          qpdf::pdf_subset(pdf_path, pages = start_page:end_page, output = output_file)
          showNotification(paste("Completed part", i, "of", length(valid_parts)), type = "message", duration = 2)
        }

        removeNotification("processing_split")
        showNotification(paste("PDF successfully split into", length(valid_parts), "parts!"), type = "message", duration = 5)
      }, error = function(e) {
        removeNotification("processing_split")
        showNotification(paste("Error splitting PDF:", e$message), type = "error", duration = 10)
      })
    })
  })
}
