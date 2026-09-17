# modules/Receipt Processor/receipt_pdf_converter.R
# Subtab: PDF to JPG Converter
#
# NOTE ON FIDELITY: the source app's error handler did
# `results_list[[i]] <- data.frame(...)` inside a tryCatch error callback.
# In R, `<-` inside a function body creates a LOCAL binding in that
# function's own environment - it does NOT reach back into the enclosing
# loop's `results_list`, so a failed conversion's error row was silently
# lost (never actually recorded), leaving a gap in results_list that
# do.call(rbind, ...) would just drop. Fixed below with `<<-`.

receipt_pdf_converter_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "PDF to JPG Converter", status = "primary", solidHeader = TRUE, width = 12,
          p(strong("Instructions:"), "Upload PDF files to convert them to JPG images. Each page will be saved as a separate JPG file."),
          hr(),
          fileInput(ns("pdf_files"), "Choose PDF Files:", multiple = TRUE, accept = c(".pdf", "application/pdf"),
                    placeholder = "Select one or more PDF files"),
          numericInput(ns("jpg_dpi"), "Image Quality (DPI):", value = 300, min = 72, max = 600, step = 50),
          p(class = "text-muted", "Higher DPI = better quality but larger file size. Recommended: 300 DPI"),
          hr(),
          textInput(ns("converter_output_path"), "Output Folder Path:", value = file.path(getwd(), "converted_images"),
                    placeholder = "Enter full path where JPG files will be saved"),
          p(class = "text-muted", strong("Example paths:")),
          p(class = "text-muted", "Windows: C:/Users/YourName/Documents/converted_images"),
          p(class = "text-muted", "Mac/Linux: /home/username/Documents/converted_images"),
          actionButton(ns("browse_converter_folder"), "Show Path Info", class = "btn-info", icon = icon("info-circle")),
          hr(),
          actionButton(ns("convert_pdf"), "Convert PDFs to JPG", class = "btn-success", icon = icon("magic")),
          hr(),
          uiOutput(ns("conversion_status")))
    ),
    fluidRow(
      box(title = "Conversion Results", status = "success", solidHeader = TRUE, width = 12,
          p("This table shows the results of PDF to JPG conversions."),
          DT::dataTableOutput(ns("conversion_results_table")))
    )
  )
}

receipt_pdf_converter_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    rv <- reactiveValues(conversion_results = NULL)

    observeEvent(input$browse_converter_folder, {
      showNotification("Enter the full folder path in the text box above. The folder will be created automatically if it doesn't exist.",
                       type = "message", duration = 8)
    })

    observeEvent(input$convert_pdf, {
      req(input$pdf_files)

      if (!requireNamespace("pdftools", quietly = TRUE)) {
        showModal(modalDialog(title = "Package Required",
          HTML("The 'pdftools' package is required for PDF conversion.<br><br>Please install it by running:<br><code>install.packages('pdftools')</code>"),
          easyClose = TRUE, footer = modalButton("OK")))
        return()
      }
      if (!requireNamespace("magick", quietly = TRUE)) {
        showModal(modalDialog(title = "Package Required",
          HTML("The 'magick' package is required for image conversion.<br><br>Please install it by running:<br><code>install.packages('magick')</code>"),
          easyClose = TRUE, footer = modalButton("OK")))
        return()
      }

      output_folder <- input$converter_output_path
      if (!dir.exists(output_folder)) {
        dir.create(output_folder, recursive = TRUE)
        showNotification(paste("Created folder:", output_folder), type = "message", duration = 3)
      }

      withProgress(message = 'Converting PDFs...', value = 0, {
        results_list <- list()

        for (i in 1:nrow(input$pdf_files)) {
          file_info <- input$pdf_files[i, ]
          incProgress(1 / nrow(input$pdf_files), detail = paste("Converting", file_info$name))

          tryCatch({
            pdf_info <- pdftools::pdf_info(file_info$datapath)
            num_pages <- pdf_info$pages
            base_name <- tools::file_path_sans_ext(file_info$name)

            page_files <- c()
            for (page_num in 1:num_pages) {
              output_filename <- if (num_pages > 1) paste0(base_name, "_page_", sprintf("%03d", page_num), ".jpg")
                                  else paste0(base_name, ".jpg")
              output_path <- file.path(output_folder, output_filename)

              img <- magick::image_read_pdf(file_info$datapath, pages = page_num, density = input$jpg_dpi)
              magick::image_write(img, output_path, format = "jpeg", quality = 95)

              page_files <- c(page_files, output_filename)
            }

            results_list[[i]] <- data.frame(pdf_file = file_info$name, pages = num_pages,
                                             output_files = paste(page_files, collapse = ", "),
                                             status = "Success", stringsAsFactors = FALSE)
          }, error = function(e) {
            results_list[[i]] <<- data.frame(pdf_file = file_info$name, pages = NA, output_files = "",
                                              status = paste("Error:", e$message), stringsAsFactors = FALSE)
          })
        }

        rv$conversion_results <- do.call(rbind, results_list)
      })

      success_count <- sum(rv$conversion_results$status == "Success")
      error_count <- nrow(rv$conversion_results) - success_count

      output$conversion_status <- renderUI({
        if (error_count > 0) {
          tags$div(class = "alert alert-success", tags$strong("Completed! "),
                   sprintf("Successfully converted %d PDF(s). %d error(s) occurred.", success_count, error_count),
                   tags$br(), tags$small(paste("Files saved to:", output_folder)))
        } else {
          tags$div(class = "alert alert-success", tags$strong("✓ Success! "),
                   sprintf("Successfully converted all %d PDF(s) to JPG images.", nrow(rv$conversion_results)),
                   tags$br(), tags$small(paste("Files saved to:", output_folder)))
        }
      })
    })

    output$conversion_results_table <- DT::renderDataTable({
      req(rv$conversion_results)
      DT::datatable(rv$conversion_results, options = list(pageLength = 10, scrollX = TRUE, dom = 'frtip'), rownames = FALSE)
    })
  })
}
