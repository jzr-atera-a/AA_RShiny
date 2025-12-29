# Upload Receipts Module

library(dplyr)

uploadUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Upload Receipt Images",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        p(strong("Instructions:"), "Upload up to 5 receipt images in JPG or JPEG format. Files will be saved with descriptive names based on the receipt content."),
        hr(),
        p(strong("Filename Format:"), "ProviderName_Description_YYYYMMDD_Amount.jpg"),
        p(strong("Examples:"), "Trainline_London_to_Manchester_20251115_14.92.jpg or Booking_com_Paris_20251110_85.50.jpg"),
        hr(),
        fileInput(
          ns("receipt_files"),
          "Choose Receipt Files (JPG or JPEG only - PDFs not supported by OpenAI Vision API)",
          multiple = TRUE,
          accept = c(".jpg", ".jpeg", "image/jpeg"),
          placeholder = "Select up to 5 files"
        ),
        actionButton(ns("process_btn"), "Process Receipts", 
                     class = "btn-primary", icon = icon("play-circle")),
        hr(),
        uiOutput(ns("upload_status"))
      )
    ),
    fluidRow(
      box(
        title = "Processing Results",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        p("The results below show the extracted information from the receipts you just processed. Amounts are stored as numeric values (no currency symbols)."),
        DT::dataTableOutput(ns("results_table"))
      )
    )
  )
}

uploadServer <- function(id, shared_rv) {
  moduleServer(id, function(input, output, session) {
    
    # Local reactive values
    rv <- reactiveValues(
      current_results = NULL
    )
    
    # Process receipts
    observeEvent(input$process_btn, {
      req(input$receipt_files)
      
      # Check API key
      if (is.null(shared_rv$api_key) || nchar(shared_rv$api_key) == 0) {
        showModal(modalDialog(
          title = "API Key Required",
          "Please set your OpenAI API key in the Settings tab first.",
          easyClose = TRUE,
          footer = modalButton("OK")
        ))
        return()
      }
      
      # Check number of files
      if (nrow(input$receipt_files) > 5) {
        showModal(modalDialog(
          title = "Too Many Files",
          "Please upload a maximum of 5 files at a time.",
          easyClose = TRUE,
          footer = modalButton("OK")
        ))
        return()
      }
      
      # Show progress bar
      withProgress(message = 'Processing receipts...', value = 0, {
        
        results_list <- list()
        
        for (i in 1:nrow(input$receipt_files)) {
          file_info <- input$receipt_files[i, ]
          incProgress(1/nrow(input$receipt_files), 
                      detail = paste("Processing", file_info$name))
          
          # Generate unique ID for this receipt (temporary)
          receipt_id <- paste0("RCP_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_", 
                               sprintf("%03d", i))
          
          # Save with temporary filename first
          temp_filename <- paste0(receipt_id, "_", file_info$name)
          temp_filepath <- file.path(shared_rv$receipts_folder, temp_filename)
          file.copy(file_info$datapath, temp_filepath)
          
          # Call OpenAI API to process the receipt
          result <- call_openai_api(file_info$datapath, file_info$name, shared_rv$api_key)
          
          # Extract and clean amount to ensure it's numeric
          amount_numeric <- if ("error" %in% names(result)) {
            0
          } else {
            amt <- result$amount
            if (is.character(amt)) {
              amt_cleaned <- gsub("[^0-9.]", "", amt)
              as.numeric(amt_cleaned)
            } else {
              as.numeric(amt)
            }
          }
          
          # Create data frame with results
          if ("error" %in% names(result)) {
            # Error occurred - keep temp filename
            results_list[[i]] <- data.frame(
              receipt_id = receipt_id,
              filename = temp_filename,
              provider = "ERROR",
              amount = 0,
              date = "ERROR",
              description = result$error,
              processed_timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
              Labour = 0L,
              Overheads = 0L,
              Materials = 0L,
              Capital_Usage = 0L,
              TS = 0L,
              Contractor = 0L,
              stringsAsFactors = FALSE
            )
          } else {
            # Success - create descriptive filename
            original_ext <- paste0(".", tools::file_ext(file_info$name))
            
            # Get smart description
            smart_description <- get_smart_description(result$provider, result$description, shared_rv$api_key)
            
            # Create descriptive filename
            descriptive_filename <- create_renamed_filename(
              result$provider,
              smart_description,
              result$date,
              amount_numeric,
              original_ext
            )
            
            # Rename the file in receipts folder
            descriptive_filepath <- file.path(shared_rv$receipts_folder, descriptive_filename)
            file.rename(temp_filepath, descriptive_filepath)
            
            # Store results with descriptive filename
            results_list[[i]] <- data.frame(
              receipt_id = receipt_id,
              filename = descriptive_filename,
              provider = ifelse(is.null(result$provider), "N/A", result$provider),
              amount = amount_numeric,
              date = ifelse(is.null(result$date), "N/A", result$date),
              description = ifelse(is.null(result$description), "N/A", result$description),
              processed_timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
              Labour = 0L,
              Overheads = 0L,
              Materials = 0L,
              Capital_Usage = 0L,
              TS = 0L,
              Contractor = 0L,
              stringsAsFactors = FALSE
            )
          }
        }
        
        # Combine all results into one data frame
        results_df <- do.call(rbind, results_list)
        rv$current_results <- results_df
        
        # Append to Excel file
        if (file.exists(shared_rv$excel_filename)) {
          # Read existing data
          existing_data <- openxlsx::read.xlsx(shared_rv$excel_filename)
          
          # Add category columns if they don't exist in existing data
          category_cols <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
          for (col in category_cols) {
            if (!col %in% names(existing_data)) {
              existing_data[[col]] <- 0L
            }
          }
          
          # Ensure amount column is numeric in existing data
          if ("amount" %in% names(existing_data)) {
            existing_data$amount <- as.numeric(existing_data$amount)
          }
          
          # Combine old and new data
          combined_data <- rbind(existing_data, results_df)
          openxlsx::write.xlsx(combined_data, shared_rv$excel_filename)
        } else {
          # Create new Excel file
          openxlsx::write.xlsx(results_df, shared_rv$excel_filename)
        }
      })
      
      # Show success message
      error_count <- sum(rv$current_results$provider == "ERROR")
      success_count <- nrow(rv$current_results) - error_count
      
      output$upload_status <- renderUI({
        if (error_count > 0) {
          tags$div(
            class = "alert alert-success",
            tags$strong("Completed! "),
            sprintf("Successfully processed %d receipt(s). %d error(s) occurred. Check the description column for error details.", 
                    success_count, error_count),
            tags$br(),
            tags$small("Files saved with descriptive names in receipts folder")
          )
        } else {
          tags$div(
            class = "alert alert-success",
            tags$strong("✓ Success! "),
            sprintf("Successfully processed all %d receipt(s). Data has been saved to %s with numeric amounts.", 
                    nrow(rv$current_results), shared_rv$excel_filename),
            tags$br(),
            tags$small("Files saved with descriptive names in receipts folder")
          )
        }
      })
    })
    
    # Display current processing results
    output$results_table <- DT::renderDataTable({
      req(rv$current_results)
      DT::datatable(
        rv$current_results,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = 'frtip',
          order = list(list(6, 'desc'))
        ),
        rownames = FALSE
      )
    })
    
  })
}
