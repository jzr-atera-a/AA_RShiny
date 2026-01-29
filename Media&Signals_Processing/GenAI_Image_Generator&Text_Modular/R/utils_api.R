# ============================================================================
# API UTILITIES - DALL-E IMAGE GENERATION
# ============================================================================

APIManager <- R6::R6Class(
  "APIManager",
  public = list(
    dalle_api_key = NULL,
    dalle_model = "dall-e-3",
    dalle_quality = "standard",
    dalle_style = "vivid",
    generated_images = NULL,
    chatgpt_model = "gpt-4o-mini",
    chatgpt_temperature = 0.7,
    chatgpt_max_tokens = 2000,
    
    initialize = function() {
      self$dalle_api_key <- ""
      self$generated_images <- data.frame(
        timestamp = character(),
        prompt = character(),
        model = character(),
        size = character(),
        filepath = character(),
        stringsAsFactors = FALSE
      )
      cat("✓ API Manager initialized\n")
    },
    
    set_dalle_key = function(key) {
      self$dalle_api_key <- trimws(key)
    },
    
    set_dalle_config = function(model = NULL, quality = NULL, style = NULL) {
      if (!is.null(model)) self$dalle_model <- model
      if (!is.null(quality)) self$dalle_quality <- quality
      if (!is.null(style)) self$dalle_style <- style
    },
    
    test_connection = function(api_key) {
      tryCatch({
        url <- "https://api.openai.com/v1/models"
        response <- httr::GET(
          url, 
          httr::add_headers(Authorization = paste("Bearer", api_key)), 
          httr::timeout(10)
        )
        status <- httr::status_code(response)
        
        if (status == 200) {
          return(list(success = TRUE, message = "✓ API Connection Successful"))
        } else if (status == 401) {
          return(list(success = FALSE, message = "✗ Invalid API key"))
        } else {
          return(list(success = FALSE, message = paste("✗ HTTP", status)))
        }
      }, error = function(e) {
        return(list(success = FALSE, message = paste("✗ Error:", e$message)))
      })
    },
    
    generate_image = function(prompt, model, size, quality = "standard", style = "vivid") {
      if (nchar(trimws(self$dalle_api_key)) == 0) {
        stop("DALL-E API key not set. Please configure in DALL-E API Settings tab.")
      }
      
      cat("🎨 Generating image...\n")
      cat("   Model:", model, "\n")
      cat("   Size:", size, "\n")
      cat("   Quality:", quality, "\n")
      cat("   Style:", style, "\n")
      cat("   Prompt length:", nchar(prompt), "characters\n")
      flush.console()
      
      url <- "https://api.openai.com/v1/images/generations"
      
      # Build request body based on model
      if (model == "dall-e-3") {
        body <- list(
          model = model,
          prompt = prompt,
          n = 1,
          size = size,
          quality = quality,
          style = style,
          response_format = "b64_json"
        )
      } else {
        # DALL-E 2
        body <- list(
          model = model,
          prompt = prompt,
          n = 1,
          size = size,
          response_format = "b64_json"
        )
      }
      
      json_body <- jsonlite::toJSON(body, auto_unbox = TRUE)
      
      cat("   📤 Sending request to OpenAI...\n")
      flush.console()
      
      response <- httr::POST(
        url,
        httr::add_headers(
          Authorization = paste("Bearer", self$dalle_api_key),
          `Content-Type` = "application/json"
        ),
        body = json_body,
        encode = "raw",
        httr::timeout(120),
        httr::config(connecttimeout = 60)
      )
      
      cat("   📥 Response received\n")
      flush.console()
      
      status <- httr::status_code(response)
      
      if (status != 200) {
        error_content <- httr::content(response, "text", encoding = "UTF-8")
        cat("   ❌ HTTP Status:", status, "\n")
        cat("   Error:", error_content, "\n")
        flush.console()
        
        if (status == 401) {
          stop("Authentication failed. Check your DALL-E API key in settings.")
        } else if (status == 429) {
          stop("Rate limit exceeded. Wait a few minutes and try again.")
        } else if (status == 400) {
          stop("Bad request. Please check your prompt and try again.")
        } else {
          stop(paste("API Error (Status", status, "):", error_content))
        }
      }
      
      content_result <- httr::content(response, "parsed", encoding = "UTF-8")
      
      if (is.null(content_result$data) || length(content_result$data) == 0) {
        cat("   ❌ No image data in response\n")
        flush.console()
        stop("No image data returned from DALL-E")
      }
      
      # Get base64 image data
      b64_image <- content_result$data[[1]]$b64_json
      
      if (is.null(b64_image) || nchar(b64_image) == 0) {
        cat("   ❌ Empty image data\n")
        flush.console()
        stop("Empty image data from DALL-E")
      }
      
      cat("   ✅ Image generated successfully\n")
      cat("   Image data size:", round(nchar(b64_image)/1024, 1), "KB\n")
      flush.console()
      
      # Decode base64 to binary
      image_binary <- base64enc::base64decode(b64_image)
      
      # Save to temporary file
      temp_file <- tempfile(fileext = ".png")
      writeBin(image_binary, temp_file)
      
      cat("   💾 Image saved to temporary file\n")
      flush.console()
      
      # Record in history
      new_record <- data.frame(
        timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        prompt = substr(prompt, 1, 100),
        model = model,
        size = size,
        filepath = temp_file,
        stringsAsFactors = FALSE
      )
      self$generated_images <- rbind(self$generated_images, new_record)
      
      return(list(
        success = TRUE,
        filepath = temp_file,
        b64_data = b64_image,
        revised_prompt = content_result$data[[1]]$revised_prompt %||% prompt
      ))
    },
    
    save_image_with_format = function(source_path, output_path, format, dpi = 300) {
      tryCatch({
        cat("💾 Saving image...\n")
        cat("   Source:", source_path, "\n")
        cat("   Output:", output_path, "\n")
        cat("   Format:", format, "\n")
        cat("   DPI:", dpi, "\n")
        flush.console()
        
        # Read the image
        img <- magick::image_read(source_path)
        
        # Get image info
        info <- magick::image_info(img)
        cat("   Original size:", info$width, "x", info$height, "\n")
        flush.console()
        
        # Convert and save based on format
        if (format == "jpg" || format == "jpeg") {
          img <- magick::image_convert(img, format = "jpeg")
          magick::image_write(img, path = output_path, format = "jpeg", quality = 100, density = dpi)
          cat("   ✅ Saved as JPEG (100% quality, ", dpi, " DPI)\n")
        } else if (format == "png") {
          img <- magick::image_convert(img, format = "png")
          magick::image_write(img, path = output_path, format = "png", density = dpi)
          cat("   ✅ Saved as PNG (lossless, ", dpi, " DPI)\n")
        } else if (format == "gif") {
          img <- magick::image_convert(img, format = "gif")
          magick::image_write(img, path = output_path, format = "gif")
          cat("   ✅ Saved as GIF\n")
        } else if (format == "tiff") {
          img <- magick::image_convert(img, format = "tiff")
          magick::image_write(img, path = output_path, format = "tiff", compression = "LZW", density = dpi)
          cat("   ✅ Saved as TIFF (LZW compression, ", dpi, " DPI)\n")
        } else if (format == "svg") {
          # For SVG, create a simple wrapper with embedded PNG
          img_png <- magick::image_convert(img, format = "png")
          png_b64 <- base64enc::base64encode(magick::image_write(img_png, format = "png"))
          
          svg_content <- sprintf(
            '<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" 
     width="%d" height="%d" viewBox="0 0 %d %d">
  <image width="%d" height="%d" xlink:href="data:image/png;base64,%s"/>
</svg>',
            info$width, info$height, info$width, info$height,
            info$width, info$height, png_b64
          )
          writeLines(svg_content, output_path)
          cat("   ✅ Saved as SVG (raster embedded)\n")
        } else if (format == "pdf") {
          # For PDF, use magick's PDF output with density
          img_pdf <- magick::image_convert(img, format = "pdf")
          magick::image_write(img_pdf, path = output_path, format = "pdf", density = dpi)
          cat("   ✅ Saved as PDF (", dpi, " DPI)\n")
        } else {
          stop("Unsupported format: ", format)
        }
        
        flush.console()
        
        return(list(success = TRUE, message = paste0("Image saved successfully as ", toupper(format), "!")))
      }, error = function(e) {
        cat("   ❌ Error saving image:", e$message, "\n")
        flush.console()
        return(list(success = FALSE, message = paste("Error:", e$message)))
      })
    },
    
    chatgpt_complete = function(messages, model = NULL, temperature = NULL, max_tokens = NULL) {
      if (nchar(trimws(self$dalle_api_key)) == 0) {
        stop("OpenAI API key not set. Please configure in API Settings tab.")
      }
      
      # Use provided parameters or defaults
      use_model <- model %||% self$chatgpt_model
      use_temperature <- temperature %||% self$chatgpt_temperature
      use_max_tokens <- max_tokens %||% self$chatgpt_max_tokens
      
      cat("🤖 Calling ChatGPT...\n")
      cat("   Model:", use_model, "\n")
      cat("   Temperature:", use_temperature, "\n")
      cat("   Max Tokens:", use_max_tokens, "\n")
      flush.console()
      
      url <- "https://api.openai.com/v1/chat/completions"
      
      body <- list(
        model = use_model,
        messages = messages,
        max_tokens = use_max_tokens,
        temperature = use_temperature
      )
      
      json_body <- jsonlite::toJSON(body, auto_unbox = TRUE)
      
      cat("   📤 Sending request to OpenAI...\n")
      flush.console()
      
      response <- httr::POST(
        url,
        httr::add_headers(
          Authorization = paste("Bearer", self$dalle_api_key),
          `Content-Type` = "application/json"
        ),
        body = json_body,
        encode = "raw",
        httr::timeout(120),
        httr::config(connecttimeout = 60)
      )
      
      cat("   📥 Response received\n")
      flush.console()
      
      status <- httr::status_code(response)
      
      if (status != 200) {
        error_content <- httr::content(response, "text", encoding = "UTF-8")
        cat("   ❌ HTTP Status:", status, "\n")
        cat("   Error:", error_content, "\n")
        flush.console()
        
        if (status == 401) {
          stop("Authentication failed. Check your OpenAI API key in settings.")
        } else if (status == 429) {
          stop("Rate limit exceeded. Wait a few minutes and try again.")
        } else {
          stop(paste("API Error (Status", status, "):", error_content))
        }
      }
      
      content_result <- httr::content(response, "parsed", encoding = "UTF-8")
      
      if (is.null(content_result$choices) || length(content_result$choices) == 0) {
        cat("   ❌ No choices in response\n")
        flush.console()
        stop("No response content from ChatGPT")
      }
      
      text_result <- content_result$choices[[1]]$message$content
      
      if (is.null(text_result) || nchar(text_result) == 0) {
        cat("   ❌ Empty response\n")
        flush.console()
        stop("Empty response from ChatGPT")
      }
      
      cat("   ✅ ChatGPT response received:", nchar(text_result), "characters\n")
      flush.console()
      
      return(text_result)
    }
  )
)
