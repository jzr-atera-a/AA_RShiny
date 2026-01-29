further_context_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Reactive values
    values <- reactiveValues(
      enriched_output = NULL
    )
    
    # Check for transferred text from image_generation module
    observe({
      if (!is.null(session$userData$transferred_text)) {
        updateTextAreaInput(session, "contextText", value = session$userData$transferred_text)
        # Clear after transferring
        session$userData$transferred_text <- NULL
      }
    })
    
    # Enrich text with ChatGPT
    observeEvent(input$enrichBtn, {
      req(input$contextText)
      
      if (nchar(trimws(input$contextText)) == 0) {
        showNotification("Please enter some text to enrich", type = "error")
        return()
      }
      
      # Show loading notification
      notification_id <- showNotification(
        "Enriching text with ChatGPT... Please wait.",
        duration = NULL,
        type = "message"
      )
      
      tryCatch({
        # Get selections
        word_count <- input$wordCount
        style <- input$textStyle
        
        # Build the instruction prompt
        instruction <- paste0(
          "Rewrite the following text in a ", style, " style with approximately ", 
          word_count, " words. Maintain the core message but enhance clarity, professionalism, and impact.\n\n",
          "Text to rewrite:\n",
          input$contextText
        )
        
        # Log the request
        log_message <- paste0(
          "=== ENRICHMENT REQUEST ===\n",
          "Word Count: ", word_count, " words\n",
          "Style: ", style, "\n",
          "Input length: ", nchar(input$contextText), " characters\n",
          "========================\n"
        )
        
        output$log <- renderText(log_message)
        
        # Call ChatGPT API
        messages <- list(
          list(role = "user", content = instruction)
        )
        
        result <- api_manager$chatgpt_complete(messages)
        
        if (!is.null(result) && nchar(result) > 0) {
          values$enriched_output <- result
          
          # Update log
          output$log <- renderText({
            paste0(
              log_message,
              "\n=== ENRICHMENT RESULT ===\n",
              "Output length: ", nchar(result), " characters\n",
              "Word count: ~", length(strsplit(result, "\\s+")[[1]]), " words\n",
              "Status: SUCCESS\n",
              "========================\n"
            )
          })
          
          removeNotification(notification_id)
          showNotification("Text enriched successfully!", type = "message", duration = 5)
        }
      }, error = function(e) {
        removeNotification(notification_id)
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
        
        output$log <- renderText({
          paste0(
            "=== ERROR ===\n",
            e$message,
            "\n============\n"
          )
        })
      })
    })
    
    # Display enriched text
    output$enrichedText <- renderText({
      if (!is.null(values$enriched_output)) {
        values$enriched_output
      } else {
        "No enriched text yet. Click 'Enrich with ChatGPT' to generate."
      }
    })
    
    # Flag for conditional panel
    output$hasEnrichedText <- reactive({
      !is.null(values$enriched_output) && nchar(values$enriched_output) > 0
    })
    outputOptions(output, "hasEnrichedText", suspendWhenHidden = FALSE)
    
    # Copy to clipboard (using JavaScript)
    observeEvent(input$copyBtn, {
      if (!is.null(values$enriched_output)) {
        # Send to JavaScript to copy
        session$sendCustomMessage(
          type = "copyToClipboard",
          message = values$enriched_output
        )
        showNotification("Copied to clipboard!", type = "message", duration = 2)
      }
    })
    
    # Replace input with enriched output
    observeEvent(input$replaceBtn, {
      if (!is.null(values$enriched_output)) {
        updateTextAreaInput(session, "contextText", value = values$enriched_output)
        showNotification("Input replaced with enriched text", type = "message", duration = 3)
      }
    })
  })
}
