# modules/Visual Media/image_generation.R
# Subtab: Image Generation (DALL-E)
# Uses api_manager$openai_api_key (same shared key as API Settings > ChatGPT
# API Config) - no separate DALL-E key/settings tab, per user decision.

image_generation_ui <- function(id) {
  ns <- NS(id)

  fluidRow(
    column(width = 4,
           box(title = "Image Generation Controls", status = "primary", solidHeader = TRUE, width = NULL,
               textAreaInput(ns("description"), "Image Description:", placeholder = "Describe the image you want to generate...", rows = 12, width = "100%"),
               actionButton(ns("transferBtn"), "Transfer to Further Context Tab", class = "btn-info",
                            style = "width: 100%; margin-bottom: 15px;", icon = icon("arrow-right")),
               selectInput(ns("style"), "Image Style:",
                           choices = c("Art-like (Digital Art)" = "art", "Photograph-like (Realistic)" = "photo"), selected = "art"),
               selectInput(ns("aspectRatio"), "Aspect Ratio:",
                           choices = c("1:1 (Square)" = "1:1", "4:3 (Standard)" = "4:3", "3:4 (Portrait)" = "3:4",
                                       "16:9 (Widescreen)" = "16:9", "9:16 (Tall Portrait)" = "9:16"), selected = "1:1"),
               h4("Dimensions", style = "margin-top: 20px; color: #667eea;"),
               fluidRow(
                 column(6, numericInput(ns("height"), "Height:", value = 10, min = 1, max = 200, step = 0.5)),
                 column(6, selectInput(ns("unit"), "Unit:", choices = c("cm", "inches"), selected = "cm"))
               ),
               div(class = "dimension-display", textOutput(ns("calculatedWidth"))),
               br(),
               h4("Model & Quality", style = "color: #667eea;"),
               fluidRow(
                 column(6, selectInput(ns("model"), "DALL-E Model:", choices = c("DALL-E 3" = "dall-e-3", "DALL-E 2" = "dall-e-2"), selected = "dall-e-3")),
                 column(6, conditionalPanel(condition = sprintf("input['%s'] == 'dall-e-3'", ns("model")),
                                             selectInput(ns("quality"), "Quality:", choices = c("Standard" = "standard", "HD" = "hd"), selected = "standard")))
               ),
               conditionalPanel(condition = sprintf("input['%s'] == 'dall-e-3'", ns("model")),
                                 selectInput(ns("dalle_style"), "DALL-E Style:", choices = c("Vivid" = "vivid", "Natural" = "natural"), selected = "vivid")),
               br(),
               actionButton(ns("generateBtn"), "Generate Image", class = "btn-success", style = "width: 100%; font-size: 16px; padding: 12px;", icon = icon("magic")),
               br(), br(),
               conditionalPanel(condition = "output.imageGenerated", ns = ns,
                                 h4("Download Options", style = "color: #667eea;"),
                                 selectInput(ns("downloadFormat"), "Download Format:",
                                             choices = c("JPG (High Quality)" = "jpg", "PNG (Lossless)" = "png", "TIFF (Professional)" = "tiff",
                                                         "GIF (Compatible)" = "gif", "PDF (Document)" = "pdf", "SVG (Scalable)" = "svg"), selected = "jpg"),
                                 textInput(ns("filename"), "Filename (without extension):", value = paste0("dalle_image_", format(Sys.time(), "%Y%m%d_%H%M%S"))),
                                 shinyDirButton(ns("downloadDir"), "Choose Download Folder", "Select folder to save image", class = "btn-info", style = "width: 100%; margin-bottom: 10px;"),
                                 verbatimTextOutput(ns("selectedPath")),
                                 br(),
                                 actionButton(ns("downloadBtn"), "Download Image", class = "btn-primary", style = "width: 100%;", icon = icon("download")))
           )
    ),
    column(width = 8,
           box(title = "Generated Image", status = "primary", solidHeader = TRUE, width = NULL,
               div(class = "image-preview-box", uiOutput(ns("imageDisplay"))),
               br(),
               conditionalPanel(condition = "output.imageGenerated", ns = ns,
                                 div(class = "prompt-box", h5(style = "margin-top: 0;", "📝 Revised Prompt:"), textOutput(ns("revisedPrompt"))))
           ),
           box(title = "Generation Log", status = "info", solidHeader = TRUE, width = NULL, collapsible = TRUE, collapsed = TRUE,
               verbatimTextOutput(ns("log")))
    )
  )
}

image_generation_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    values <- reactiveValues(image_path = NULL, revised_prompt = NULL, download_dir = NULL)

    volumes <- get_volume_roots()
    shinyDirChoose(input, "downloadDir", roots = volumes, session = session)

    observeEvent(input$transferBtn, {
      if (!is.null(input$description) && nchar(trimws(input$description)) > 0) {
        api_manager$set_pending_prompt_visual_media(input$description)
        updateTabItems(session$rootScope(), "sidebar_menu", "further_context")
        showNotification("Description transferred to Further Context tab!", type = "message", duration = 3)
      } else {
        showNotification("Please enter a description first", type = "warning")
      }
    })

    output$calculatedWidth <- renderText({
      width <- calculate_width(input$height, input$aspectRatio, input$unit)
      paste0("Width: ", width, " ", input$unit, " (based on ", input$aspectRatio, " ratio)")
    })

    observeEvent(input$downloadDir, {
      if (!is.null(input$downloadDir) && !is.integer(input$downloadDir)) {
        dir_selected <- parseDirPath(volumes, input$downloadDir)
        if (length(dir_selected) > 0) values$download_dir <- as.character(dir_selected)
      }
    })

    output$selectedPath <- renderText({
      if (!is.null(values$download_dir)) paste("Selected:", values$download_dir) else "No folder selected"
    })

    observeEvent(input$generateBtn, {
      req(input$description)
      if (nchar(trimws(input$description)) == 0) { showNotification("Please enter an image description", type = "error"); return() }
      if (!api_manager$openai_authenticated) {
        showNotification("Please configure your ChatGPT/OpenAI API key first (API Settings > ChatGPT API Config)!", type = "error", duration = 5)
        return()
      }

      notification_id <- showNotification("Generating image... This may take 10-30 seconds.", duration = NULL, type = "message")

      tryCatch({
        enhanced_prompt <- enhance_prompt(input$description, input$style)
        dalle_size <- get_dalle_size(input$aspectRatio, input$model)

        log_message <- paste0(
          "=== GENERATION REQUEST ===\nModel: ", input$model, "\nSize: ", dalle_size, "\nQuality: ", input$quality,
          "\nStyle: ", input$dalle_style, "\nAspect Ratio: ", input$aspectRatio, "\nDimensions: ", input$height, " ", input$unit, " (height)\n",
          "Original Prompt: ", input$description, "\nEnhanced Prompt: ", enhanced_prompt, "\n========================\n"
        )
        output$log <- renderText(log_message)

        result <- api_manager$generate_dalle_image(prompt = enhanced_prompt, model = input$model, size = dalle_size,
                                                     quality = input$quality %||% "standard", style = input$dalle_style %||% "vivid")

        if (result$success) {
          values$image_path <- result$filepath
          values$revised_prompt <- result$revised_prompt

          output$log <- renderText(paste0(log_message, "\n=== GENERATION RESULT ===\nStatus: SUCCESS\nImage saved to: ", result$filepath,
                                          "\nRevised Prompt: ", result$revised_prompt, "\n========================\n"))

          removeNotification(notification_id)
          showNotification("Image generated successfully!", type = "message", duration = 5)
        }
      }, error = function(e) {
        removeNotification(notification_id)
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
        output$log <- renderText(paste0("=== ERROR ===\n", e$message, "\n============\n"))
      })
    })

    output$imageDisplay <- renderUI({
      if (!is.null(values$image_path) && file.exists(values$image_path)) {
        img_data <- base64enc::base64encode(values$image_path)
        tags$img(src = paste0("data:image/png;base64,", img_data),
                 style = "max-width: 100%; max-height: 600px; border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,0.15);")
      } else {
        div(style = "text-align: center; color: #999;", icon("image", class = "fa-3x"), br(), br(),
            h4("No image generated yet"), p("Enter a description and click 'Generate Image' to start"))
      }
    })

    output$imageGenerated <- reactive({ !is.null(values$image_path) && file.exists(values$image_path) })
    outputOptions(output, "imageGenerated", suspendWhenHidden = FALSE)

    output$revisedPrompt <- renderText({ if (!is.null(values$revised_prompt)) values$revised_prompt else "" })

    do_download <- function(overwrite_ok = FALSE) {
      req(values$image_path, input$filename)
      if (is.null(values$download_dir)) { showNotification("Please select a download folder first", type = "warning"); return() }
      if (nchar(trimws(input$filename)) == 0) { showNotification("Please enter a filename", type = "warning"); return() }

      tryCatch({
        format_ext <- input$downloadFormat
        output_filename <- paste0(input$filename, ".", format_ext)
        output_path <- file.path(values$download_dir, output_filename)

        if (file.exists(output_path) && !overwrite_ok) {
          showModal(modalDialog(title = "File Exists", paste("File", output_filename, "already exists. Overwrite?"),
                                footer = tagList(modalButton("Cancel"), actionButton(session$ns("confirmOverwrite"), "Overwrite", class = "btn-danger"))))
          return()
        }

        result <- api_manager$save_image_with_format(source_path = values$image_path, output_path = output_path, format = format_ext, dpi = 300)

        if (result$success) showNotification(paste("Image saved successfully to:", output_path), type = "message", duration = 10)
        else showNotification(result$message, type = "error", duration = 10)
      }, error = function(e) showNotification(paste("Error saving image:", e$message), type = "error", duration = 10))
    }

    observeEvent(input$downloadBtn, { do_download(overwrite_ok = FALSE) })
    observeEvent(input$confirmOverwrite, { removeModal(); do_download(overwrite_ok = TRUE) })
  })
}
