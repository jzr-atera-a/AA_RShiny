# modules/Receipt Processor/receipt_upload.R
# Subtab: Upload Receipts

receipt_upload_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Upload Receipt Images", status = "primary", solidHeader = TRUE, width = 12,
          p(strong("Instructions:"), "Upload up to 5 receipt images in JPG or JPEG format. Files will be saved with descriptive names based on the receipt content."),
          hr(),
          p(strong("Filename Format:"), "ProviderName_Description_YYYYMMDD_Amount.jpg"),
          p(strong("Examples:"), "Trainline_London_to_Manchester_20251115_14.92.jpg or Booking_com_Paris_20251110_85.50.jpg"),
          hr(),
          fileInput(ns("receipt_files"), "Choose Receipt Files (JPG or JPEG only - PDFs not supported by OpenAI Vision API)",
                    multiple = TRUE, accept = c(".jpg", ".jpeg", "image/jpeg"), placeholder = "Select up to 5 files"),
          actionButton(ns("process_btn"), "Process Receipts", class = "btn-primary", icon = icon("play-circle")),
          hr(),
          uiOutput(ns("upload_status")))
    ),
    fluidRow(
      box(title = "Processing Results", status = "success", solidHeader = TRUE, width = 12,
          p("The results below show the extracted information from the receipts you just processed. Amounts are stored as numeric values (no currency symbols)."),
          DT::dataTableOutput(ns("results_table")))
    )
  )
}

receipt_upload_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    rv <- reactiveValues(current_results = NULL)

    observeEvent(input$process_btn, {
      req(input$receipt_files)

      if (nchar(api_manager$receipt_api_key) == 0) {
        showModal(modalDialog(title = "API Key Required", "Please set your OpenAI API key in the Settings tab first.",
                              easyClose = TRUE, footer = modalButton("OK")))
        return()
      }

      if (nrow(input$receipt_files) > 5) {
        showModal(modalDialog(title = "Too Many Files", "Please upload a maximum of 5 files at a time.",
                              easyClose = TRUE, footer = modalButton("OK")))
        return()
      }

      withProgress(message = 'Processing receipts...', value = 0, {
        results_list <- list()

        for (i in 1:nrow(input$receipt_files)) {
          file_info <- input$receipt_files[i, ]
          incProgress(1 / nrow(input$receipt_files), detail = paste("Processing", file_info$name))

          receipt_id <- paste0("RCP_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_", sprintf("%03d", i))
          temp_filename <- paste0(receipt_id, "_", file_info$name)
          temp_filepath <- file.path(api_manager$receipt_folder, temp_filename)
          file.copy(file_info$datapath, temp_filepath)

          result <- api_manager$call_receipt_api(file_info$datapath, file_info$name)

          amount_numeric <- if ("error" %in% names(result)) {
            0
          } else {
            amt <- result$amount
            if (is.character(amt)) as.numeric(gsub("[^0-9.]", "", amt)) else as.numeric(amt)
          }

          if ("error" %in% names(result)) {
            results_list[[i]] <- data.frame(
              receipt_id = receipt_id, filename = temp_filename, provider = "ERROR", amount = 0,
              date = "ERROR", description = result$error, processed_timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
              Labour = 0L, Overheads = 0L, Materials = 0L, Capital_Usage = 0L, TS = 0L, Contractor = 0L,
              stringsAsFactors = FALSE
            )
          } else {
            original_ext <- paste0(".", tools::file_ext(file_info$name))
            smart_description <- api_manager$get_receipt_smart_description(result$provider, result$description)
            descriptive_filename <- create_renamed_filename(result$provider, smart_description, result$date, amount_numeric, original_ext)

            descriptive_filepath <- file.path(api_manager$receipt_folder, descriptive_filename)
            file.rename(temp_filepath, descriptive_filepath)

            results_list[[i]] <- data.frame(
              receipt_id = receipt_id, filename = descriptive_filename,
              provider = ifelse(is.null(result$provider), "N/A", result$provider),
              amount = amount_numeric, date = ifelse(is.null(result$date), "N/A", result$date),
              description = ifelse(is.null(result$description), "N/A", result$description),
              processed_timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
              Labour = 0L, Overheads = 0L, Materials = 0L, Capital_Usage = 0L, TS = 0L, Contractor = 0L,
              stringsAsFactors = FALSE
            )
          }
        }

        results_df <- do.call(rbind, results_list)
        rv$current_results <- results_df

        if (file.exists(api_manager$receipt_excel_filename)) {
          existing_data <- openxlsx::read.xlsx(api_manager$receipt_excel_filename)

          category_cols <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
          for (col in category_cols) if (!col %in% names(existing_data)) existing_data[[col]] <- 0L

          if ("amount" %in% names(existing_data)) existing_data$amount <- as.numeric(existing_data$amount)

          combined_data <- rbind(existing_data, results_df)
          openxlsx::write.xlsx(combined_data, api_manager$receipt_excel_filename)
        } else {
          openxlsx::write.xlsx(results_df, api_manager$receipt_excel_filename)
        }
      })

      error_count <- sum(rv$current_results$provider == "ERROR")
      success_count <- nrow(rv$current_results) - error_count

      output$upload_status <- renderUI({
        if (error_count > 0) {
          tags$div(class = "alert alert-success", tags$strong("Completed! "),
                   sprintf("Successfully processed %d receipt(s). %d error(s) occurred. Check the description column for error details.", success_count, error_count),
                   tags$br(), tags$small("Files saved with descriptive names in receipts folder"))
        } else {
          tags$div(class = "alert alert-success", tags$strong("✓ Success! "),
                   sprintf("Successfully processed all %d receipt(s). Data has been saved to %s with numeric amounts.", nrow(rv$current_results), api_manager$receipt_excel_filename),
                   tags$br(), tags$small("Files saved with descriptive names in receipts folder"))
        }
      })
    })

    output$results_table <- DT::renderDataTable({
      req(rv$current_results)
      DT::datatable(rv$current_results,
                    options = list(pageLength = 10, scrollX = TRUE, dom = 'frtip', order = list(list(6, 'desc'))),
                    rownames = FALSE)
    })
  })
}
