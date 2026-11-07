# Statements to Table Module

library(dplyr)
library(DT)
library(shinyFiles)

statementsToTableUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Upload Bank Statement Images",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        p(strong("Instructions:"), "Upload bank statement files (JPG, JPEG, GIF, or PDF format). The AI will extract transactions into a table."),
        hr(),
        fileInput(
          ns("statement_files"),
          "Choose Statement Files (JPG, JPEG, GIF, or PDF)",
          multiple = TRUE,
          accept = c(".jpg", ".jpeg", ".gif", ".pdf", "image/jpeg", "image/gif", "application/pdf"),
          placeholder = "Select one or more statement files"
        ),
        actionButton(ns("process_statements_btn"), "Process Statements", 
                     class = "btn-primary", icon = icon("play-circle")),
        hr(),
        uiOutput(ns("processing_status"))
      )
    ),
    fluidRow(
      box(
        title = "Extracted Transactions",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        p("Edit the 'Sign' column if any transaction sign is incorrect. Positive for deposits/income/refunds, negative for charges/expenses."),
        hr(),
        DT::dataTableOutput(ns("transactions_table")),
        hr(),
        fluidRow(
          column(6,
            textInput(ns("save_filename"), "File Name:", value = "bank_transactions", width = "100%")
          ),
          column(3,
            selectInput(ns("file_format"), "Format:", 
                       choices = c("Excel (.xlsx)" = "xlsx", "CSV (.csv)" = "csv"),
                       selected = "xlsx", width = "100%")
          ),
          column(3,
            br(),
            actionButton(ns("save_btn"), "Save File", 
                        class = "btn-success", icon = icon("save"), width = "100%")
          )
        )
      )
    )
  )
}

statementsToTableServer <- function(id, shared_rv) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Local reactive values
    rv <- reactiveValues(
      transactions_data = NULL,
      save_path = NULL
    )
    
    # Initialize shinyFiles for directory selection
    volumes <- reactive({
      get_folder_volumes()
    })
    
    shinyDirChoose(input, "save_dir", roots = volumes, session = session)
    
    # Process bank statements
    observeEvent(input$process_statements_btn, {
      req(input$statement_files)
      
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
      
      # Show progress bar
      withProgress(message = 'Processing bank statements...', value = 0, {
        
        all_transactions <- list()
        
        for (i in 1:nrow(input$statement_files)) {
          file_info <- input$statement_files[i, ]
          incProgress(1/nrow(input$statement_files), 
                      detail = paste("Processing", file_info$name))
          
          # Call OpenAI API to extract transactions
          result <- extract_bank_transactions(file_info$datapath, file_info$name, shared_rv$api_key)
          
          if ("error" %in% names(result)) {
            showNotification(
              paste("Error processing", file_info$name, ":", result$error),
              type = "error",
              duration = 10
            )
          } else if (!is.null(result$transactions)) {
            all_transactions[[i]] <- result$transactions
          }
        }
        
        # Combine all transactions
        if (length(all_transactions) > 0) {
          combined_df <- do.call(rbind, all_transactions)
          
          # Sort by date (oldest first)
          combined_df <- combined_df %>%
            arrange(Date)
          
          rv$transactions_data <- combined_df
          
          output$processing_status <- renderUI({
            tags$div(
              class = "alert alert-success",
              tags$strong("✓ Success! "),
              sprintf("Extracted %d transaction(s) from %d statement file(s).", 
                      nrow(combined_df), length(all_transactions))
            )
          })
        } else {
          output$processing_status <- renderUI({
            tags$div(
              class = "alert alert-warning",
              tags$strong("⚠ Warning: "),
              "No transactions were extracted. Please check the statement files and try again."
            )
          })
        }
      })
    })
    
    # Render editable transactions table
    output$transactions_table <- DT::renderDataTable({
      req(rv$transactions_data)
      
      DT::datatable(
        rv$transactions_data,
        editable = list(target = 'cell', disable = list(columns = c(0, 1, 2, 3, 5, 6))),
        options = list(
          pageLength = 25,
          scrollX = TRUE,
          dom = 'Bfrtip',
          order = list(list(0, 'asc'))
        ),
        rownames = FALSE
      )
    })
    
    # Handle cell edits
    observeEvent(input$transactions_table_cell_edit, {
      info <- input$transactions_table_cell_edit
      i <- info$row
      j <- info$col + 1
      v <- info$value
      
      # Only allow editing the Sign column (column 4)
      if (j == 4) {
        # Validate that the value is either "Positive" or "Negative"
        if (v %in% c("Positive", "Negative")) {
          rv$transactions_data[i, j] <- v
          
          # Recalculate the Amount column based on new sign
          magnitude <- rv$transactions_data$Amount_Magnitude[i]
          rv$transactions_data$Amount[i] <- if (v == "Positive") magnitude else -magnitude
        } else {
          showNotification("Sign must be either 'Positive' or 'Negative'", type = "warning")
        }
      }
    })
    
    # Save file button
    observeEvent(input$save_btn, {
      req(rv$transactions_data)
      req(input$save_filename)
      
      # Show file save dialog
      shinyFileSave(input, "save_file", roots = volumes(), session = session)
      
      tryCatch({
        # Get file extension
        file_ext <- if (input$file_format == "xlsx") ".xlsx" else ".csv"
        
        # Clean filename
        clean_filename <- gsub("[^a-zA-Z0-9_-]", "_", input$save_filename)
        default_filename <- paste0(clean_filename, file_ext)
        
        # Use base R file chooser as fallback
        file_path <- tryCatch({
          if (.Platform$OS.type == "windows") {
            choose.files(default = default_filename, caption = "Save File As", multi = FALSE, filters = matrix(c("All Files", "*.*"), ncol = 2))
          } else {
            file.choose()
          }
        }, error = function(e) {
          # If file dialog fails, save to current directory
          file.path(getwd(), default_filename)
        })
        
        if (length(file_path) > 0 && !is.na(file_path)) {
          # Ensure correct extension
          if (!grepl(paste0("\\", file_ext, "$"), file_path, ignore.case = TRUE)) {
            file_path <- paste0(tools::file_path_sans_ext(file_path), file_ext)
          }
          
          # Save based on format
          if (input$file_format == "xlsx") {
            openxlsx::write.xlsx(rv$transactions_data, file_path)
          } else {
            write.csv(rv$transactions_data, file_path, row.names = FALSE)
          }
          
          showModal(modalDialog(
            title = "✓ File Saved",
            paste("Transactions saved successfully to:", file_path),
            easyClose = TRUE,
            footer = modalButton("OK")
          ))
        }
      }, error = function(e) {
        showModal(modalDialog(
          title = "Error Saving File",
          paste("Failed to save file:", e$message),
          easyClose = TRUE,
          footer = modalButton("OK")
        ))
      })
    })
    
  })
}

# Helper function to extract bank transactions from statement images
extract_bank_transactions <- function(file_path, filename, api_key) {
  if (is.null(api_key) || nchar(api_key) == 0) {
    return(list(error = "API key not set"))
  }
  
  # Encode file to base64
  base64_data <- encode_file(file_path)
  media_type <- get_media_type(filename)
  
  # Prepare content based on file type
  if (media_type == "application/pdf") {
    # For PDFs, we need to convert to images first or use text extraction
    # For now, return error as OpenAI Vision doesn't support PDFs directly
    return(list(error = "PDF support requires conversion to images. Please convert your PDF to JPG/JPEG first using the 'PDF to JPG Converter' tab."))
  }
  
  # Prepare API request
  api_url <- "https://api.openai.com/v1/chat/completions"
  
  body <- list(
    model = "gpt-4o",
    messages = list(
      list(
        role = "user",
        content = list(
          list(
            type = "image_url",
            image_url = list(
              url = paste0("data:", media_type, ";base64,", base64_data)
            )
          ),
          list(
            type = "text",
            text = paste0(
              "Analyze this bank statement image and extract ALL transactions into a structured format.\n\n",
              "For each transaction, determine:\n",
              "1. Date (YYYY-MM-DD format)\n",
              "2. Seller/Description (merchant or transaction description)\n",
              "3. Description (additional details if available)\n",
              "4. Amount (the actual transaction value - positive for deposits/credits/refunds, negative for withdrawals/debits/charges)\n",
              "5. Account_Balance (the balance after this transaction, if visible)\n\n",
              "CRITICAL RULES for Amount:\n",
              "- Deposits, credits, income, refunds = POSITIVE numbers (e.g., 500.00)\n",
              "- Withdrawals, debits, charges, payments = NEGATIVE numbers (e.g., -125.50)\n",
              "- Return ONLY numeric values, no currency symbols\n\n",
              "Return a JSON object with a 'transactions' array:\n",
              "{\n",
              '  "transactions": [\n',
              '    {\n',
              '      "date": "2025-01-15",\n',
              '      "seller": "Merchant Name",\n',
              '      "description": "Transaction details",\n',
              '      "amount": -125.50,\n',
              '      "account_balance": 1234.56\n',
              '    }\n',
              '  ]\n',
              '}\n\n',
              "DO NOT include markdown formatting or backticks. Return ONLY the JSON object.\n",
              "Ensure amounts are NUMBERS, not strings.\n",
              "Sort transactions by date from earliest to latest."
            )
          )
        )
      )
    ),
    max_tokens = 4000
  )
  
  # Make API request
  response <- tryCatch({
    httr::POST(
      url = api_url,
      httr::add_headers(
        `Authorization` = paste("Bearer", api_key),
        `Content-Type` = "application/json"
      ),
      body = body,
      encode = "json",
      httr::timeout(120)
    )
  }, error = function(e) {
    return(list(error = paste("API request failed:", e$message)))
  })
  
  if ("error" %in% names(response)) {
    return(response)
  }
  
  # Parse response
  if (httr::status_code(response) == 200) {
    content <- httr::content(response, "parsed")
    if (!is.null(content$choices) && length(content$choices) > 0) {
      response_text <- content$choices[[1]]$message$content
      
      # Clean up response text
      response_text <- gsub("```json\\s*", "", response_text)
      response_text <- gsub("```\\s*", "", response_text)
      response_text <- trimws(response_text)
      
      # Parse JSON
      tryCatch({
        parsed_data <- jsonlite::fromJSON(response_text)
        
        if (!is.null(parsed_data$transactions) && nrow(parsed_data$transactions) > 0) {
          # Process transactions into desired format
          transactions_df <- parsed_data$transactions %>%
            mutate(
              Date = as.character(date),
              Seller = as.character(seller),
              Description = as.character(description),
              Amount = as.numeric(amount),
              Sign = ifelse(Amount >= 0, "Positive", "Negative"),
              Amount_Magnitude = abs(Amount),
              Account_Balance = as.numeric(account_balance)
            ) %>%
            select(Date, Seller, Description, Sign, Amount, Amount_Magnitude, Account_Balance)
          
          return(list(transactions = transactions_df))
        } else {
          return(list(error = "No transactions found in the statement"))
        }
      }, error = function(e) {
        return(list(error = paste("Failed to parse JSON response:", e$message)))
      })
    } else {
      return(list(error = "API returned empty response"))
    }
  } else if (httr::status_code(response) == 401) {
    return(list(error = "Authentication failed. Check your API key."))
  } else if (httr::status_code(response) == 429) {
    return(list(error = "Rate limit exceeded. Please wait and try again."))
  } else {
    return(list(error = paste("API error: Status code", httr::status_code(response))))
  }
}
