# Invoice Management Module

invoice_management_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Upload Section
    fluidRow(
      box(
        width = 6,
        title = "Upload Transaction Data",
        status = "primary",
        solidHeader = TRUE,
        
        fileInput(
          ns("excel_file"),
          "Upload Excel File:",
          accept = c(".xlsx", ".xls"),
          placeholder = "Select categorized expenses file"
        ),
        
        uiOutput(ns("file_info"))
      ),
      
      box(
        width = 6,
        title = "Upload Sample Invoice (Optional)",
        status = "warning",
        solidHeader = TRUE,
        
        fileInput(
          ns("sample_invoice"),
          "Upload Sample Invoice PDF:",
          accept = c(".pdf"),
          placeholder = "Upload to mimic style"
        ),
        
        uiOutput(ns("sample_info"))
      )
    ),
    
    # Data Table Section
    fluidRow(
      box(
        width = 12,
        title = "Transaction Data",
        status = "primary",
        solidHeader = TRUE,
        collapsible = TRUE,
        
        DTOutput(ns("transaction_table")),
        
        br(),
        
        fluidRow(
          column(width = 4, valueBoxOutput(ns("total_transactions"), width = 12)),
          column(width = 4, valueBoxOutput(ns("total_amount"), width = 12)),
          column(width = 4, valueBoxOutput(ns("invoices_available"), width = 12))
        )
      )
    ),
    
    # Invoice Generation Section
    fluidRow(
      box(
        width = 12,
        title = "Generate Invoice",
        status = "success",
        solidHeader = TRUE,
        
        fluidRow(
          column(
            width = 8,
            h4("Selected Transaction:"),
            verbatimTextOutput(ns("selected_transaction")),
            
            textAreaInput(
              ns("custom_instructions"),
              "Additional Invoice Details:",
              placeholder = "Add any custom details, company information, payment terms, notes, etc.",
              rows = 4,
              width = "100%"
            ),
            
            textInput(
              ns("invoice_number"),
              "Invoice Number (optional):",
              placeholder = "Auto-generated if left blank"
            )
          ),
          
          column(
            width = 4,
            br(), br(),
            actionButton(
              ns("generate_invoice"),
              "Generate Invoice with AI",
              icon = icon("magic"),
              class = "btn-generate btn-lg btn-block"
            ),
            br(),
            downloadButton(
              ns("download_invoice"),
              "Download Invoice PDF",
              class = "btn-primary btn-block"
            ),
            br(),
            actionButton(
              ns("mark_available"),
              "Mark as Available",
              icon = icon("check"),
              class = "btn-info btn-block"
            )
          )
        ),
        
        hr(),
        h4("Generation Status:"),
        uiOutput(ns("generation_status")),
        h4("Preview:"),
        uiOutput(ns("invoice_preview"))
      )
    )
  )
}

invoice_management_server <- function(id, shared_rv) {
  moduleServer(id, function(input, output, session) {
    
    rv <- reactiveValues(
      data = NULL,
      selected_row = NULL,
      generated_invoice = NULL,
      sample_invoice_text = NULL
    )
    
    # Handle Excel Upload
    observeEvent(input$excel_file, {
      req(input$excel_file)
      tryCatch({
        data <- readxl::read_excel(input$excel_file$datapath)
        
        if (!"Available_Invoices" %in% names(data)) data$Available_Invoices <- 0
        if (!"Invoice" %in% names(data)) data$Invoice <- 0
        
        rv$data <- data
        showNotification("File uploaded successfully!", type = "message")
      }, error = function(e) {
        showNotification(paste("Error reading file:", e$message), type = "error", duration = 10)
      })
    })
    
    output$file_info <- renderUI({
      req(rv$data)
      div(class = "status-box status-success",
          icon("check"), sprintf(" Loaded %d transactions", nrow(rv$data)))
    })
    
    # Handle Sample Invoice PDF Upload
    observeEvent(input$sample_invoice, {
      req(input$sample_invoice)
      tryCatch({
        text <- pdftools::pdf_text(input$sample_invoice$datapath)
        rv$sample_invoice_text <- paste(text, collapse = "\n")
        showNotification("Sample invoice uploaded successfully!", type = "message")
      }, error = function(e) {
        showNotification(paste("Error reading PDF:", e$message), type = "error", duration = 10)
      })
    })
    
    output$sample_info <- renderUI({
      if (!is.null(rv$sample_invoice_text)) {
        div(class = "status-box status-success",
            icon("check"), " Sample invoice loaded - style will be matched")
      }
    })
    
    # Transaction Table
    output$transaction_table <- renderDT({
      req(rv$data)
      datatable(
        rv$data,
        selection = "single",
        editable = list(target = "cell", disable = list(columns = c(0:(ncol(rv$data)-3)))),
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          columnDefs = list(list(className = 'dt-center', targets = "_all"))
        ),
        class = "display cell-border stripe hover"
      )
    })
    
    observeEvent(input$transaction_table_cell_edit, {
      info <- input$transaction_table_cell_edit
      rv$data[info$row, info$col] <- info$value
    })
    
    # Value Boxes
    output$total_transactions <- renderValueBox({
      req(rv$data)
      valueBox(nrow(rv$data), "Total Transactions", icon = icon("list"), color = "blue")
    })
    
    output$total_amount <- renderValueBox({
      req(rv$data)
      total <- sum(rv$data$Expense, na.rm = TRUE)
      valueBox(paste("£", format(round(total, 2), big.mark = ",")), "Total Amount", icon = icon("pound-sign"), color = "green")
    })
    
    output$invoices_available <- renderValueBox({
      req(rv$data)
      available <- sum(rv$data$Available_Invoices == 1, na.rm = TRUE)
      valueBox(available, "Invoices Available", icon = icon("file-invoice"), color = "yellow")
    })
    
    # Row Selection
    observeEvent(input$transaction_table_rows_selected, {
      req(input$transaction_table_rows_selected)
      rv$selected_row <- input$transaction_table_rows_selected
    })
    
    output$selected_transaction <- renderPrint({
      req(rv$selected_row, rv$data)
      selected <- rv$data[rv$selected_row, ]
      cat("Date:", as.character(selected$Date), "\n")
      cat("Details:", as.character(selected$Details), "\n")
      cat("Amount: £", selected$Expense, "\n")
      if ("Seller_Group" %in% names(selected)) {
        cat("Vendor Group:", as.character(selected$Seller_Group), "\n")
      }
    })
    
    # Generate Invoice via OpenAI
    observeEvent(input$generate_invoice, {
      req(shared_rv$api_key, rv$selected_row, rv$data)
      
      withProgress(message = 'Generating invoice...', value = 0, {
        selected <- rv$data[rv$selected_row, ]
        
        prompt <- sprintf(
"Generate a professional invoice in HTML format for the following transaction:

Date: %s
Vendor/Details: %s
Amount: £%.2f
Seller Group: %s

%s

%s

Requirements:
1. Create a complete, professional invoice in HTML format
2. Include all standard invoice elements (invoice number, date, from/to addresses, itemization, total)
3. Make it print-ready and professional
4. Include payment terms and contact information placeholders
5. Use clean, modern styling with CSS embedded in the HTML
6. The invoice should be ready to convert to PDF

Return ONLY the HTML code, no explanations.",
          as.character(selected$Date),
          as.character(selected$Details),
          selected$Expense,
          ifelse("Seller_Group" %in% names(selected), as.character(selected$Seller_Group), "N/A"),
          ifelse(nchar(input$custom_instructions) > 0, paste("Additional Details:", input$custom_instructions), ""),
          ifelse(!is.null(rv$sample_invoice_text),
                 paste("Please match the style and format of this sample invoice:\n", substr(rv$sample_invoice_text, 1, 2000)), "")
        )
        
        incProgress(0.3, detail = "Calling OpenAI API...")
        
        tryCatch({
          response <- httr::POST(
            url = "https://api.openai.com/v1/chat/completions",
            httr::add_headers(
              "Authorization" = paste("Bearer", shared_rv$api_key),
              "Content-Type" = "application/json"
            ),
            body = jsonlite::toJSON(list(
              model = "gpt-4-turbo-preview",
              messages = list(
                list(role = "system", content = "You are an expert at creating professional invoices. Generate clean, well-formatted HTML invoices."),
                list(role = "user", content = prompt)
              ),
              max_tokens = 2000,
              temperature = 0.3
            ), auto_unbox = TRUE),
            encode = "json"
          )
          
          incProgress(0.6, detail = "Processing response...")
          
          if (httr::status_code(response) == 200) {
            content_response <- httr::content(response, "parsed")
            rv$generated_invoice <- content_response$choices[[1]]$message$content
            
            # Clean markdown wrapping if present
            rv$generated_invoice <- gsub("```html\\n", "", rv$generated_invoice)
            rv$generated_invoice <- gsub("```\\n", "", rv$generated_invoice)
            rv$generated_invoice <- gsub("```", "", rv$generated_invoice)
            
            incProgress(1, detail = "Complete!")
            showNotification("Invoice generated successfully!", type = "message")
          } else {
            error_msg <- httr::content(response)$error$message
            showNotification(paste("API Error:", error_msg), type = "error", duration = 10)
          }
        }, error = function(e) {
          showNotification(paste("Error:", e$message), type = "error", duration = 10)
        })
      })
    })
    
    # Generation Status
    output$generation_status <- renderUI({
      if (!is.null(rv$generated_invoice)) {
        div(class = "status-box status-success",
            icon("check-circle"), " Invoice generated successfully! Preview below or download as PDF.")
      } else {
        div(class = "status-box status-info",
            icon("info-circle"), " Select a transaction and click 'Generate Invoice with AI' to create an invoice.")
      }
    })
    
    # Invoice Preview
    output$invoice_preview <- renderUI({
      req(rv$generated_invoice)
      HTML(rv$generated_invoice)
    })
    
    # Download Invoice as PDF
    output$download_invoice <- downloadHandler(
      filename = function() {
        paste0("invoice_", format(Sys.Date(), "%Y%m%d"), "_", gsub(":", "", format(Sys.time(), "%H%M%S")), ".pdf")
      },
      content = function(file) {
        req(rv$generated_invoice)
        temp_html <- tempfile(fileext = ".html")
        writeLines(rv$generated_invoice, temp_html)
        
        tryCatch({
          if (require("pagedown", quietly = TRUE)) {
            pagedown::chrome_print(temp_html, file, wait = 2)
          } else {
            showNotification("Install 'pagedown' for PDF export. Saving as HTML instead.", type = "warning", duration = 10)
            file.copy(temp_html, file)
          }
        }, error = function(e) {
          showNotification(paste("PDF error:", e$message), type = "error")
          file.copy(temp_html, file)
        })
      }
    )
    
    # Mark as Available
    observeEvent(input$mark_available, {
      req(rv$selected_row, rv$data)
      rv$data[rv$selected_row, "Available_Invoices"] <- 1
      showNotification("Marked as available!", type = "message")
    })
  })
}
