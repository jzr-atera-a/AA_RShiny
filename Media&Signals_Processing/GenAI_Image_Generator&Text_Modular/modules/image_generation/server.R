image_generation_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Reactive values
    values <- reactiveValues(
      generated_image = NULL,
      image_path = NULL,
      revised_prompt = NULL,
      download_dir = NULL,
      transfer_text = NULL
    )
    
    # Setup directory chooser
    volumes <- get_volume_roots()
    shinyFiles::shinyDirChoose(input, "downloadDir", roots = volumes, session = session)
    
    # Handle transfer to Further Context tab
    observeEvent(input$transferBtn, {
      if (!is.null(input$description) && nchar(trimws(input$description)) > 0) {
        # Store in session data so it can be accessed by further_context module
        session$userData$transferred_text <- input$description
        
        # Switch to Further Context tab
        updateTabItems(session, "sidebar_menu", selected = "further_context")
        
        showNotification("Description transferred to Further Context tab!", type = "message", duration = 3)
      } else {
        showNotification("Please enter a description first", type = "warning")
      }
    })
    
    # Calculate and display width
    output$calculatedWidth <- renderText({
      height <- input$height
      aspect_ratio <- input$aspectRatio
      unit <- input$unit
      
      width <- calculate_width(height, aspect_ratio, unit)
      
      paste0("Width: ", width, " ", unit, " (based on ", aspect_ratio, " ratio)")
    })
    
    # Observe directory selection
    observeEvent(input$downloadDir, {
      if (!is.null(input$downloadDir) && !is.integer(input$downloadDir)) {
        dir_selected <- shinyFiles::parseDirPath(volumes, input$downloadDir)
        if (length(dir_selected) > 0) {
          values$download_dir <- as.character(dir_selected)
        }
      }
    })
    
    # Display selected path
    output$selectedPath <- renderText({
      if (!is.null(values$download_dir)) {
        paste("Selected:", values$download_dir)
      } else {
        "No folder selected"
      }
    })
    
    # Generate image
    observeEvent(input$generateBtn, {
      req(input$description)
      
      if (nchar(trimws(input$description)) == 0) {
        showNotification("Please enter an image description", type = "error")
        return()
      }
      
      # Show loading notification
      notification_id <- showNotification(
        "Generating image... This may take 10-30 seconds.",
        duration = NULL,
        type = "message"
      )
      
      tryCatch({
        # Get model from API manager
        model <- api_manager$dalle_model
        
        # Enhance prompt based on style
        enhanced_prompt <- enhance_prompt(input$description, input$style)
        
        # Get DALL-E size based on aspect ratio and model
        dalle_size <- get_dalle_size(input$aspectRatio, model)
        
        # Get quality and style settings
        quality <- api_manager$dalle_quality
        style_setting <- api_manager$dalle_style
        
        # Log generation attempt
        log_message <- paste0(
          "=== GENERATION REQUEST ===\n",
          "Model: ", model, "\n",
          "Size: ", dalle_size, "\n",
          "Quality: ", quality, "\n",
          "Style: ", style_setting, "\n",
          "Aspect Ratio: ", input$aspectRatio, "\n",
          "Dimensions: ", input$height, " ", input$unit, " (height)\n",
          "Original Prompt: ", input$description, "\n",
          "Enhanced Prompt: ", enhanced_prompt, "\n",
          "========================\n"
        )
        
        output$log <- renderText(log_message)
        
        # Generate image
        result <- api_manager$generate_image(
          prompt = enhanced_prompt,
          model = model,
          size = dalle_size,
          quality = quality,
          style = style_setting
        )
        
        if (result$success) {
          values$image_path <- result$filepath
          values$revised_prompt <- result$revised_prompt
          
          # Update log
          output$log <- renderText({
            paste0(
              log_message,
              "\n=== GENERATION RESULT ===\n",
              "Status: SUCCESS\n",
              "Image saved to: ", result$filepath, "\n",
              "Revised Prompt: ", result$revised_prompt, "\n",
              "========================\n"
            )
          })
          
          removeNotification(notification_id)
          showNotification("Image generated successfully!", type = "message", duration = 5)
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
    
    # Display generated image
    output$imageDisplay <- renderUI({
      if (!is.null(values$image_path) && file.exists(values$image_path)) {
        # Read image as base64
        img_data <- base64enc::base64encode(values$image_path)
        
        tags$img(
          src = paste0("data:image/png;base64,", img_data),
          style = "max-width: 100%; max-height: 600px; border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,0.15);"
        )
      } else {
        div(
          style = "text-align: center; color: #999;",
          icon("image", class = "fa-3x"),
          br(), br(),
          h4("No image generated yet"),
          p("Enter a description and click 'Generate Image' to start")
        )
      }
    })
    
    # Flag for conditional panel
    output$imageGenerated <- reactive({
      !is.null(values$image_path) && file.exists(values$image_path)
    })
    outputOptions(output, "imageGenerated", suspendWhenHidden = FALSE)
    
    # Display revised prompt
    output$revisedPrompt <- renderText({
      if (!is.null(values$revised_prompt)) {
        values$revised_prompt
      } else {
        ""
      }
    })
    
    # Download image
    observeEvent(input$downloadBtn, {
      req(values$image_path)
      req(input$filename)
      
      if (is.null(values$download_dir)) {
        showNotification("Please select a download folder first", type = "warning")
        return()
      }
      
      if (nchar(trimws(input$filename)) == 0) {
        showNotification("Please enter a filename", type = "warning")
        return()
      }
      
      tryCatch({
        # Build output path
        format_ext <- input$downloadFormat
        output_filename <- paste0(input$filename, ".", format_ext)
        output_path <- file.path(values$download_dir, output_filename)
        
        # Check if file exists
        if (file.exists(output_path)) {
          showModal(modalDialog(
            title = "File Exists",
            paste("File", output_filename, "already exists. Overwrite?"),
            footer = tagList(
              modalButton("Cancel"),
              actionButton(ns("confirmOverwrite"), "Overwrite", class = "btn-danger")
            )
          ))
          return()
        }
        
        # Save image with format conversion
        result <- api_manager$save_image_with_format(
          source_path = values$image_path,
          output_path = output_path,
          format = format_ext,
          dpi = 300
        )
        
        if (result$success) {
          showNotification(
            paste("Image saved successfully to:", output_path),
            type = "message",
            duration = 10
          )
        } else {
          showNotification(result$message, type = "error", duration = 10)
        }
      }, error = function(e) {
        showNotification(paste("Error saving image:", e$message), type = "error", duration = 10)
      })
    })
    
    # Handle overwrite confirmation
    observeEvent(input$confirmOverwrite, {
      req(values$image_path)
      req(input$filename)
      req(values$download_dir)
      
      removeModal()
      
      tryCatch({
        format_ext <- input$downloadFormat
        output_filename <- paste0(input$filename, ".", format_ext)
        output_path <- file.path(values$download_dir, output_filename)
        
        result <- api_manager$save_image_with_format(
          source_path = values$image_path,
          output_path = output_path,
          format = format_ext,
          dpi = 300
        )
        
        if (result$success) {
          showNotification(
            paste("Image saved successfully to:", output_path),
            type = "message",
            duration = 10
          )
        } else {
          showNotification(result$message, type = "error", duration = 10)
        }
      }, error = function(e) {
        showNotification(paste("Error saving image:", e$message), type = "error", duration = 10)
      })
    })
  })
}
