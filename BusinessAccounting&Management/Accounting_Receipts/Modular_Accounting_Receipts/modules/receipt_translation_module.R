# Receipt Translation & Reformat Module

receipt_translation_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        width = 12,
        title = "Translation/Reformat Settings",
        status = "primary",
        solidHeader = TRUE,
        
        fluidRow(
          column(
            width = 6,
            selectInput(
              ns("translation_mode"),
              "Select Mode:",
              choices = c(
                "Spanish to English (Translation)" = "spanish_to_english",
                "English to English (Reformat)" = "english_to_english"
              ),
              selected = "spanish_to_english"
            )
          ),
          column(
            width = 6,
            uiOutput(ns("mode_description"))
          )
        )
      )
    ),
    
    fluidRow(
      box(
        width = 6,
        title = "Upload Receipts",
        status = "info",
        solidHeader = TRUE,
        
        uiOutput(ns("receipts_upload_ui")),
        
        hr(),
        uiOutput(ns("receipts_status"))
      ),
      
      box(
        width = 6,
        title = "Upload Sample Template (Required)",
        status = "warning",
        solidHeader = TRUE,
        
        fileInput(
          ns("sample_template"),
          "Select Sample Receipt Template:",
          accept = c(".pdf", ".jpg", ".jpeg", ".png"),
          placeholder = "PDF or JPEG format"
        ),
        
        p(strong("Note:"), "The generated receipts will match this template's structure, logos, and colors exactly."),
        
        hr(),
        uiOutput(ns("sample_status"))
      )
    ),
    
    fluidRow(
      box(
        width = 12,
        title = "Additional Instructions",
        status = "success",
        solidHeader = TRUE,
        
        textAreaInput(
          ns("custom_instructions"),
          "Provide Additional Details:",
          placeholder = "For English to English mode without uploaded receipts: commerce name, amount, product/service, date, etc.\nFor any mode: specific formatting requirements, additional details, corrections, etc.",
          rows = 6,
          width = "100%"
        ),
        
        p(strong("Note:"), "Even without additional instructions, the AI will process based on uploaded files and selected mode.")
      )
    ),
    
    fluidRow(
      box(
        width = 12,
        title = "Generate Translated/Reformatted Receipts",
        status = "success",
        solidHeader = TRUE,
        
        fluidRow(
          column(
            width = 8,
            h4("Processing Summary:"),
            uiOutput(ns("processing_summary"))
          ),
          column(
            width = 4,
            br(),
            actionButton(
              ns("generate_receipts"),
              "Generate Receipt PDFs",
              icon = icon("magic"),
              class = "btn-generate btn-lg btn-block"
            )
          )
        ),
        
        hr(),
        
        h4("Generation Status:"),
        uiOutput(ns("generation_status")),
        
        hr(),
        
        h4("Download Generated Receipts:"),
        uiOutput(ns("download_buttons"))
      )
    )
  )
}

receipt_translation_server <- function(id, shared_rv) {
  moduleServer(id, function(input, output, session) {
    
    rv <- reactiveValues(
      receipt_files = NULL,
      sample_template = NULL,
      sample_template_text = NULL,
      generated_receipts = list(),
      processing_complete = FALSE
    )
    
    # Mode Description
    output$mode_description <- renderUI({
      if (input$translation_mode == "spanish_to_english") {
        tags$div(
          class = "alert alert-info",
          style = "margin-top: 25px;",
          icon("info-circle"),
          " Upload Spanish receipts (required) and a sample template. AI will translate and match the template format."
        )
      } else {
        tags$div(
          class = "alert alert-warning",
          style = "margin-top: 25px;",
          icon("exclamation-triangle"),
          " Upload English receipts (optional) and a sample template. If no receipts uploaded, provide details in the text box."
        )
      }
    })
    
    # Dynamic Receipts Upload UI
    output$receipts_upload_ui <- renderUI({
      ns <- session$ns
      
      if (input$translation_mode == "spanish_to_english") {
        tagList(
          fileInput(
            ns("receipt_files"),
            "Upload Spanish Receipts (Required):",
            accept = c(".pdf"),
            multiple = TRUE,
            placeholder = "Select up to 8 PDF files"
          ),
          p(strong("Required:"), "Upload 1-8 Spanish receipt PDF files for translation.")
        )
      } else {
        tagList(
          fileInput(
            ns("receipt_files"),
            "Upload English Receipts (Optional):",
            accept = c(".pdf"),
            multiple = TRUE,
            placeholder = "Select up to 8 PDF files"
          ),
          p(strong("Optional:"), "Upload receipts to reformat, or leave empty and provide details in text box below.")
        )
      }
    })
    
    # Handle Receipt Files Upload
    observeEvent(input$receipt_files, {
      req(input$receipt_files)
      
      if (nrow(input$receipt_files) > 8) {
        showNotification("Maximum 8 files allowed. Only first 8 will be used.", type = "warning", duration = 5)
        rv$receipt_files <- input$receipt_files[1:8, ]
      } else {
        rv$receipt_files <- input$receipt_files
      }
    })
    
    output$receipts_status <- renderUI({
      if (!is.null(rv$receipt_files)) {
        div(class = "status-box status-success",
            icon("check"), sprintf(" Loaded %d receipt file(s)", nrow(rv$receipt_files)))
      } else if (input$translation_mode == "spanish_to_english") {
        div(class = "status-box status-error",
            icon("exclamation-circle"), " Spanish receipts are required for translation mode")
      } else {
        div(class = "status-box status-info",
            icon("info-circle"), " No receipts uploaded - will generate from text box instructions")
      }
    })
    
    # Handle Sample Template Upload
    observeEvent(input$sample_template, {
      req(input$sample_template)
      
      tryCatch({
        file_ext <- tolower(tools::file_ext(input$sample_template$name))
        
        if (file_ext == "pdf") {
          # Extract text from PDF
          text <- pdftools::pdf_text(input$sample_template$datapath)
          rv$sample_template_text <- paste(text, collapse = "\n")
        } else {
          # For images, just store the path for base64 encoding later
          rv$sample_template_text <- "IMAGE_FILE"
        }
        
        rv$sample_template <- input$sample_template
        showNotification("Sample template uploaded successfully!", type = "message")
      }, error = function(e) {
        showNotification(paste("Error reading template:", e$message), type = "error", duration = 10)
      })
    })
    
    output$sample_status <- renderUI({
      if (!is.null(rv$sample_template)) {
        div(class = "status-box status-success",
            icon("check"), " Sample template loaded - format will be matched exactly")
      } else {
        div(class = "status-box status-error",
            icon("exclamation-circle"), " Sample template is required")
      }
    })
    
    # Processing Summary
    output$processing_summary <- renderUI({
      mode_text <- if (input$translation_mode == "spanish_to_english") "Spanish → English Translation" else "English → English Reformat"
      receipt_count <- if (!is.null(rv$receipt_files)) nrow(rv$receipt_files) else 0
      sample_loaded <- !is.null(rv$sample_template)
      
      tagList(
        tags$ul(
          tags$li(strong("Mode:"), mode_text),
          tags$li(strong("Receipts to process:"), receipt_count),
          tags$li(strong("Sample template:"), if (sample_loaded) "✓ Loaded" else "✗ Not loaded"),
          tags$li(strong("Additional instructions:"), if (nchar(input$custom_instructions) > 0) "✓ Provided" else "None")
        )
      )
    })
    
    # Generate Receipts
    observeEvent(input$generate_receipts, {
      # Validation
      if (is.null(rv$sample_template)) {
        showNotification("Sample template is required!", type = "error", duration = 5)
        return()
      }
      
      if (input$translation_mode == "spanish_to_english" && is.null(rv$receipt_files)) {
        showNotification("Spanish receipts are required for translation mode!", type = "error", duration = 5)
        return()
      }
      
      if (input$translation_mode == "english_to_english" && is.null(rv$receipt_files) && nchar(input$custom_instructions) == 0) {
        showNotification("Either upload receipts or provide details in the text box!", type = "error", duration = 5)
        return()
      }
      
      if (is.null(shared_rv$api_key)) {
        showNotification("Please configure OpenAI API key in Settings tab first!", type = "error", duration = 5)
        return()
      }
      
      # Reset generated receipts
      rv$generated_receipts <- list()
      rv$processing_complete <- FALSE
      
      # Determine number of receipts to generate
      num_receipts <- if (!is.null(rv$receipt_files)) nrow(rv$receipt_files) else 1
      
      withProgress(message = 'Processing receipts...', value = 0, {
        
        for (i in 1:num_receipts) {
          incProgress(1/num_receipts, detail = paste("Processing receipt", i, "of", num_receipts))
          
          # Build the prompt
          if (input$translation_mode == "spanish_to_english") {
            # Extract Spanish receipt text
            spanish_text <- pdftools::pdf_text(rv$receipt_files$datapath[i])
            spanish_text <- paste(spanish_text, collapse = "\n")
            
            prompt <- sprintf(
"You are a professional receipt translator and formatter.

TASK: Translate this Spanish receipt to English and format it EXACTLY like the sample template provided.

SPANISH RECEIPT CONTENT:
%s

SAMPLE TEMPLATE TO MATCH:
%s

ADDITIONAL INSTRUCTIONS:
%s

REQUIREMENTS:
1. Translate ALL text from Spanish to English
2. Match the EXACT structure, layout, and formatting of the sample template
3. Preserve all logos, colors, and visual elements from the sample
4. Ensure all dates, amounts, and details are accurate
5. Generate complete, professional HTML receipt ready for PDF conversion
6. Include embedded CSS for styling
7. Make it print-ready and professional

Return ONLY the HTML code for the translated receipt, no explanations.",
              spanish_text,
              substr(rv$sample_template_text, 1, 3000),
              if (nchar(input$custom_instructions) > 0) input$custom_instructions else "None provided"
            )
            
          } else {
            # English to English mode
            if (!is.null(rv$receipt_files)) {
              # Reformat existing English receipt
              english_text <- pdftools::pdf_text(rv$receipt_files$datapath[i])
              english_text <- paste(english_text, collapse = "\n")
              
              prompt <- sprintf(
"You are a professional receipt formatter.

TASK: Reformat this English receipt to match the sample template EXACTLY.

ORIGINAL RECEIPT CONTENT:
%s

SAMPLE TEMPLATE TO MATCH:
%s

ADDITIONAL INSTRUCTIONS:
%s

REQUIREMENTS:
1. Extract all relevant information from the original receipt
2. Format it EXACTLY like the sample template (structure, layout, colors, logos)
3. Preserve all data accuracy (dates, amounts, items, etc.)
4. Generate complete, professional HTML receipt ready for PDF conversion
5. Include embedded CSS for styling
6. Make it print-ready and professional

Return ONLY the HTML code for the reformatted receipt, no explanations.",
                english_text,
                substr(rv$sample_template_text, 1, 3000),
                if (nchar(input$custom_instructions) > 0) input$custom_instructions else "None provided"
              )
              
            } else {
              # Generate from scratch using text box
              prompt <- sprintf(
"You are a professional receipt generator.

TASK: Generate a professional receipt based on the information provided, matching the sample template EXACTLY.

SAMPLE TEMPLATE TO MATCH:
%s

RECEIPT INFORMATION:
%s

REQUIREMENTS:
1. Create a complete professional receipt using the provided information
2. Match the EXACT structure, layout, and formatting of the sample template
3. Include all standard receipt elements (business name, date, items, amounts, total, etc.)
4. Preserve all logos, colors, and visual elements from the sample
5. Generate complete, professional HTML receipt ready for PDF conversion
6. Include embedded CSS for styling
7. Make it print-ready and professional

Return ONLY the HTML code for the receipt, no explanations.",
                substr(rv$sample_template_text, 1, 3000),
                input$custom_instructions
              )
            }
          }
          
          # Call OpenAI API with 24-hour timeout
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
                  list(role = "system", content = "You are an expert at creating professional receipts in HTML format with exact template matching."),
                  list(role = "user", content = prompt)
                ),
                max_tokens = 4000,
                temperature = 0.3
              ), auto_unbox = TRUE),
              encode = "json",
              httr::timeout(86400)  # 24 hours in seconds
            )
            
            if (httr::status_code(response) == 200) {
              content_response <- httr::content(response, "parsed")
              html_content <- content_response$choices[[1]]$message$content
              
              # Clean markdown wrapping
              html_content <- gsub("```html\\n", "", html_content)
              html_content <- gsub("```\\n", "", html_content)
              html_content <- gsub("```", "", html_content)
              
              # Store generated receipt
              receipt_name <- if (!is.null(rv$receipt_files)) {
                paste0(tools::file_path_sans_ext(rv$receipt_files$name[i]), "_translated")
              } else {
                paste0("generated_receipt_", i)
              }
              
              rv$generated_receipts[[receipt_name]] <- html_content
              
            } else {
              error_msg <- httr::content(response)$error$message
              showNotification(paste("API Error for receipt", i, ":", error_msg), type = "error", duration = 10)
            }
            
          }, error = function(e) {
            showNotification(paste("Error processing receipt", i, ":", e$message), type = "error", duration = 10)
          })
        }
        
        rv$processing_complete <- TRUE
        showNotification(paste("Successfully generated", length(rv$generated_receipts), "receipt(s)!"), type = "message", duration = 5)
      })
    })
    
    # Generation Status
    output$generation_status <- renderUI({
      if (rv$processing_complete && length(rv$generated_receipts) > 0) {
        div(class = "status-box status-success",
            icon("check-circle"), sprintf(" Successfully generated %d receipt(s)! Download below.", length(rv$generated_receipts)))
      } else if (rv$processing_complete && length(rv$generated_receipts) == 0) {
        div(class = "status-box status-error",
            icon("exclamation-circle"), " Generation failed. Check the messages above.")
      } else {
        div(class = "status-box status-info",
            icon("info-circle"), " Click 'Generate Receipt PDFs' to start processing.")
      }
    })
    
    # Download Buttons
    output$download_buttons <- renderUI({
      req(length(rv$generated_receipts) > 0)
      
      ns <- session$ns
      
      buttons <- lapply(names(rv$generated_receipts), function(receipt_name) {
        column(
          width = 3,
          downloadButton(
            ns(paste0("download_", gsub("[^a-zA-Z0-9]", "_", receipt_name))),
            label = basename(receipt_name),
            class = "btn-primary",
            style = "width: 100%; margin-bottom: 10px;"
          )
        )
      })
      
      fluidRow(buttons)
    })
    
    # Dynamic download handlers
    observe({
      req(length(rv$generated_receipts) > 0)
      
      lapply(names(rv$generated_receipts), function(receipt_name) {
        button_id <- paste0("download_", gsub("[^a-zA-Z0-9]", "_", receipt_name))
        html_content <- rv$generated_receipts[[receipt_name]]
        
        output[[button_id]] <- downloadHandler(
          filename = function() {
            paste0(receipt_name, ".pdf")
          },
          content = function(file) {
            temp_html <- tempfile(fileext = ".html")
            writeLines(html_content, temp_html)
            
            tryCatch({
              if (require("pagedown", quietly = TRUE)) {
                pagedown::chrome_print(temp_html, file, wait = 2)
              } else {
                showNotification("Install 'pagedown' for PDF export. Saving as HTML.", type = "warning", duration = 10)
                file.copy(temp_html, file)
              }
            }, error = function(e) {
              showNotification(paste("PDF error:", e$message), type = "error")
              file.copy(temp_html, file)
            })
          }
        )
      })
    })
  })
}
