# modules/Visual Media/pdf_text_extractor.R
# Subtab: Text Extractor

pdf_text_extractor_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "PDF Text Extractor Configuration", status = "primary", solidHeader = TRUE, width = 12,
          h4("Select PDF Files"),
          p("Select up to 10 PDF files (max 20 MB each). Text will be extracted from each and combined into a single .txt file, with each file's content under a header showing its filename. Images are ignored; embedded text (including most mathematical text/symbols) is extracted as-is.",
            style = "color: #6c757d; font-style: italic;"),
          fileInput(ns("extract_pdfs"), "Select PDF Files (up to 10):", accept = c(".pdf"), multiple = TRUE, placeholder = "No files selected"),
          hr(),
          fluidRow(
            column(9, div(class = "directory-display", textOutput(ns("selected_extract_save_path")))),
            column(3, shinySaveButton(ns("extract_save_select"), "Choose Save Location & Name", "Save extracted text as...",
                                       filetype = list(txt = "txt"), class = "btn-primary", style = "width: 100%;"))
          ),
          br(),
          fluidRow(column(12, actionButton(ns("extract_text_btn"), "Extract Text & Save", class = "btn-primary btn-lg", style = "width: 100%;"))))
    ),
    fluidRow(box(title = "Selected Files Summary", status = "info", solidHeader = TRUE, width = 12,
                 div(class = "info-box", verbatimTextOutput(ns("extract_files_summary"))))),
    fluidRow(box(title = "Extraction Status", status = "info", solidHeader = TRUE, width = 12,
                 div(class = "info-box", verbatimTextOutput(ns("extract_status")))))
  )
}

pdf_text_extractor_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    MAX_EXTRACT_FILES <- 10
    MAX_EXTRACT_FILE_SIZE_MB <- 20
    MAX_EXTRACT_FILE_SIZE_BYTES <- MAX_EXTRACT_FILE_SIZE_MB * 1024 * 1024

    volumes <- get_volume_roots()
    shinyFileSave(input, "extract_save_select", roots = volumes, session = session,
                  filetype = list(txt = "txt"), restrictions = system.file(package = "base"))

    values <- reactiveValues(extract_save_path = NULL,
                              extract_status_text = "Select PDF files, choose a save location & filename, then click 'Extract Text & Save'.")

    observe({
      if (!is.null(input$extract_save_select) && !is.integer(input$extract_save_select)) {
        tryCatch({
          fileinfo <- parseSavePath(volumes, input$extract_save_select)
          if (nrow(fileinfo) > 0) {
            save_path <- as.character(fileinfo$datapath[1])
            if (!grepl("\\.txt$", save_path, ignore.case = TRUE)) save_path <- paste0(save_path, ".txt")
            values$extract_save_path <- save_path
            showNotification("Save location selected successfully!", type = "message", duration = 2)
          }
        }, error = function(e) showNotification(paste("Error selecting save location:", e$message), type = "warning"))
      }
    })

    output$selected_extract_save_path <- renderText({
      if (is.null(values$extract_save_path) || length(values$extract_save_path) == 0) "No save location selected - Click 'Choose Save Location & Name'"
      else values$extract_save_path
    })

    output$extract_files_summary <- renderText({
      if (is.null(input$extract_pdfs)) {
        "No PDF files selected yet. Please select up to 10 PDF files (max 20 MB each)."
      } else {
        files_df <- input$extract_pdfs
        n_files <- nrow(files_df)

        summary_text <- paste0("Selected Files (", n_files, "):\n\n")
        for (i in 1:n_files) {
          file_size_mb <- round(files_df$size[i] / 1024 / 1024, 2)
          oversized <- files_df$size[i] > MAX_EXTRACT_FILE_SIZE_BYTES
          summary_text <- paste0(summary_text, i, ". ", files_df$name[i], " (", file_size_mb, " MB)",
                                 if (oversized) paste0("  ⚠ EXCEEDS ", MAX_EXTRACT_FILE_SIZE_MB, " MB LIMIT") else "", "\n")
        }

        if (n_files > MAX_EXTRACT_FILES) {
          summary_text <- paste0(summary_text, "\n⚠ You selected ", n_files, " files. Only the first ", MAX_EXTRACT_FILES,
                                 " will be processed - please re-select ", MAX_EXTRACT_FILES, " or fewer files.")
        }

        if (any(files_df$size > MAX_EXTRACT_FILE_SIZE_BYTES)) {
          summary_text <- paste0(summary_text, "\n⚠ One or more files exceed the ", MAX_EXTRACT_FILE_SIZE_MB, " MB limit and will be skipped during extraction.")
        }

        summary_text
      }
    })

    observeEvent(input$extract_text_btn, {
      req(input$extract_pdfs)

      if (is.null(values$extract_save_path) || length(values$extract_save_path) == 0 || values$extract_save_path == "") {
        showNotification("Please choose a save location and filename first.", type = "warning", duration = 5)
        values$extract_status_text <- "❌ Error: No save location selected. Click 'Choose Save Location & Name'."
        return()
      }

      files_df <- input$extract_pdfs
      if (nrow(files_df) > MAX_EXTRACT_FILES) {
        showNotification(paste("Please select", MAX_EXTRACT_FILES, "or fewer PDF files."), type = "warning", duration = 5)
        values$extract_status_text <- paste0("❌ Error: ", nrow(files_df), " files selected. Maximum is ", MAX_EXTRACT_FILES, ".")
        return()
      }

      showNotification("Extracting text from PDFs... This may take a while for large files.", type = "message", duration = NULL, id = "processing_extract")
      values$extract_status_text <- paste0("Processing ", nrow(files_df), " PDF file(s)...")

      tryCatch({
        output_dir <- dirname(values$extract_save_path)
        if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

        combined_parts <- character(0)
        processed_count <- 0
        skipped_files <- character(0)

        withProgress(message = "Extracting PDF text", value = 0, {
          n_files <- nrow(files_df)

          for (i in 1:n_files) {
            file_name <- files_df$name[i]
            file_path <- files_df$datapath[i]
            file_size <- files_df$size[i]

            incProgress(1 / n_files, detail = paste("Processing", file_name))

            if (file_size > MAX_EXTRACT_FILE_SIZE_BYTES) {
              skipped_files <- c(skipped_files, paste0(file_name, " (exceeds ", MAX_EXTRACT_FILE_SIZE_MB, " MB limit)"))
              next
            }

            file_section <- tryCatch({
              if (!file.exists(file_path)) stop("File does not exist or cannot be accessed")

              pages_text <- pdftools::pdf_text(file_path)
              if (is.null(pages_text) || length(pages_text) == 0) stop("No extractable text found in this PDF")

              page_blocks <- character(length(pages_text))
              for (p in seq_along(pages_text)) page_blocks[p] <- paste0("--- Page ", p, " ---\n", pages_text[p])
              full_text <- paste(page_blocks, collapse = "\n\n")

              paste0(strrep("=", 70), "\nFILE: ", file_name, "\n", strrep("=", 70), "\n\n", full_text)
            }, error = function(e) {
              skipped_files <<- c(skipped_files, paste0(file_name, " (error: ", e$message, ")"))
              paste0(strrep("=", 70), "\nFILE: ", file_name, "\n", strrep("=", 70), "\n\n",
                     "[ERROR: Could not extract text from this file - ", e$message, "]")
            })

            combined_parts <- c(combined_parts, file_section)
            processed_count <- processed_count + 1
          }
        })

        if (length(combined_parts) == 0) stop("No files could be processed. All files were skipped or exceeded the size limit.")

        final_content <- paste(combined_parts, collapse = "\n\n\n")

        con <- file(values$extract_save_path, open = "w", encoding = "UTF-8")
        writeLines(final_content, con, useBytes = TRUE)
        close(con)

        removeNotification("processing_extract")

        status_msg <- paste0("✅ Successfully extracted text from ", processed_count, " of ", nrow(files_df), " file(s)!\n\n",
                             "Output: ", basename(values$extract_save_path), "\nLocation: ", values$extract_save_path)

        if (length(skipped_files) > 0) {
          status_msg <- paste0(status_msg, "\n\n⚠ Skipped/problem files:\n", paste0("- ", skipped_files, collapse = "\n"))
        }

        values$extract_status_text <- status_msg

        showNotification(paste("Text extracted and saved to:", basename(values$extract_save_path)), type = "message", duration = 5)
      }, error = function(e) {
        removeNotification("processing_extract")
        values$extract_status_text <- paste0("❌ Error extracting text:\n", e$message)
        showNotification(paste("Error extracting text:", e$message), type = "error", duration = 10)
      })
    })

    output$extract_status <- renderText({ values$extract_status_text })
  })
}
