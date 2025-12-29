# Convert Images to PDF Module

library(shinyFiles)

toPdfConverterUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Convert Images to PDF",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        p(strong("Instructions:"), "Convert JPG, JPEG, PNG, and other image files to PDF format. Browse and select individual files or an entire folder."),
        hr(),
        radioButtons(
          ns("pdf_input_type"),
          "Select Input Type:",
          choices = c("Individual Files" = "files", "Entire Folder" = "folder"),
          selected = "files"
        ),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'files'", ns("pdf_input_type")),
          ns = ns,
          fileInput(
            ns("image_files_to_pdf"),
            "Choose Image Files:",
            multiple = TRUE,
            accept = c(".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".gif", "image/*"),
            placeholder = "Select one or more image files"
          )
        ),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'folder'", ns("pdf_input_type")),
          ns = ns,
          shinyDirButton(
            ns("image_folder_browser"),
            "Browse for Input Folder",
            "Select folder containing images",
            class = "btn-primary",
            icon = icon("folder-open")
          ),
          hr(),
          verbatimTextOutput(ns("selected_input_folder")),
          verbatimTextOutput(ns("input_folder_status"))
        ),
        hr(),
        selectInput(
          ns("pdf_page_size"),
          "PDF Page Size:",
          choices = c("A4" = "A4", "Letter" = "letter"),
          selected = "A4"
        ),
        p(class = "text-muted", "A4: 210 x 297 mm (International) | Letter: 8.5 x 11 inches (US)"),
        hr(),
        shinyDirButton(
          ns("pdf_output_browser"),
          "Browse for Output Folder",
          "Select folder to save PDF files",
          class = "btn-primary",
          icon = icon("folder-open")
        ),
        hr(),
        verbatimTextOutput(ns("selected_output_folder")),
        verbatimTextOutput(ns("output_folder_status")),
        hr(),
        actionButton(ns("convert_to_pdf"), "Convert to PDF", 
                     class = "btn-success", icon = icon("file-pdf")),
        hr(),
        uiOutput(ns("pdf_conversion_status"))
      )
    ),
    fluidRow(
      box(
        title = "Conversion Results",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        p("This table shows the results of image to PDF conversions. Original image files are NOT deleted."),
        DT::dataTableOutput(ns("pdf_conversion_results_table"))
      )
    )
  )
}

toPdfConverterServer <- function(id, shared_rv) {
  moduleServer(id, function(input, output, session) {
    
    # Local reactive values
    rv <- reactiveValues(
      pdf_conversion_results = NULL,
      selected_input_folder = NULL,
      selected_output_folder = NULL
    )
    
    # Initialize folder browsers
    volumes <- get_folder_volumes()
    
    # Input folder browser
    shinyDirChoose(input, "image_folder_browser", roots = volumes, session = session, restrictions = system.file(package = "base"))
    
    # Output folder browser
    shinyDirChoose(input, "pdf_output_browser", roots = volumes, session = session, restrictions = system.file(package = "base"))
    
    # Handle input folder selection
    observeEvent(input$image_folder_browser, {
      if (!is.integer(input$image_folder_browser)) {
        folder_path <- parseDirPath(volumes, input$image_folder_browser)
        
        if (length(folder_path) > 0) {
          folder_path <- as.character(folder_path)
          
          if (dir.exists(folder_path)) {
            rv$selected_input_folder <- folder_path
            
            output$selected_input_folder <- renderText({
              paste0("Selected folder:\n", folder_path)
            })
            
            # Count image files
            image_extensions <- c("jpg", "jpeg", "png", "bmp", "tiff", "tif", "gif")
            all_files <- list.files(folder_path, full.names = FALSE)
            image_files <- all_files[tolower(tools::file_ext(all_files)) %in% image_extensions]
            
            if (length(image_files) == 0) {
              output$input_folder_status <- renderText({
                paste0("\n⚠️ No image files found in this folder.\n",
                       "Supported formats: JPG, JPEG, PNG, BMP, TIFF, GIF")
              })
              showNotification("No image files found in folder", type = "warning", duration = 5)
            } else {
              output$input_folder_status <- renderText({
                paste0("\n✓ Found ", length(image_files), " image file(s):\n",
                       paste(head(image_files, 10), collapse = "\n"),
                       ifelse(length(image_files) > 10, "\n... and more", ""))
              })
              showNotification(paste("Found", length(image_files), "image files"), 
                               type = "message", duration = 3)
            }
          }
        }
      }
    })
    
    # Handle output folder selection
    observeEvent(input$pdf_output_browser, {
      if (!is.integer(input$pdf_output_browser)) {
        folder_path <- parseDirPath(volumes, input$pdf_output_browser)
        
        if (length(folder_path) > 0) {
          folder_path <- as.character(folder_path)
          rv$selected_output_folder <- folder_path
          
          if (!dir.exists(folder_path)) {
            dir.create(folder_path, recursive = TRUE)
          }
          
          output$selected_output_folder <- renderText({
            paste0("Selected folder:\n", folder_path)
          })
          
          output$output_folder_status <- renderText({
            paste0("\n✓ PDF files will be saved here.")
          })
          
          showNotification("Output folder selected", type = "message", duration = 3)
        }
      }
    })
    
    # Convert to PDF
    observeEvent(input$convert_to_pdf, {
      
      # Check if magick package is available
      if (!requireNamespace("magick", quietly = TRUE)) {
        showModal(modalDialog(
          title = "Package Required",
          HTML("The 'magick' package is required for PDF conversion.<br><br>
               Please install it by running:<br>
               <code>install.packages('magick')</code>"),
          easyClose = TRUE,
          footer = modalButton("OK")
        ))
        return()
      }
      
      # Get list of files to convert
      files_to_convert <- NULL
      
      if (input$pdf_input_type == "files") {
        req(input$image_files_to_pdf)
        files_to_convert <- input$image_files_to_pdf
      } else {
        folder_val <- rv$selected_input_folder
        if (is.null(folder_val) || length(folder_val) == 0) {
          showNotification("Please select input folder first", type = "error", duration = 5)
          return()
        }
        
        folder_path <- as.character(folder_val)
        
        if (!dir.exists(folder_path)) {
          showNotification(paste("Folder does not exist:", folder_path), type = "error", duration = 5)
          return()
        }
        
        # Get all image files from folder
        image_extensions <- c("jpg", "jpeg", "png", "bmp", "tiff", "tif", "gif")
        all_files <- list.files(folder_path, full.names = TRUE)
        image_files <- all_files[tolower(tools::file_ext(all_files)) %in% image_extensions]
        
        if (length(image_files) == 0) {
          showNotification("No image files found in the folder.", type = "warning", duration = 5)
          return()
        }
        
        files_to_convert <- data.frame(
          name = basename(image_files),
          datapath = image_files,
          stringsAsFactors = FALSE
        )
      }
      
      # Get output folder
      output_val <- rv$selected_output_folder
      if (is.null(output_val) || length(output_val) == 0) {
        showNotification("Please select output folder first", type = "error", duration = 5)
        return()
      }
      
      output_folder <- as.character(output_val)
      
      if (!dir.exists(output_folder)) {
        dir.create(output_folder, recursive = TRUE)
      }
      
      # Get page size
      page_size <- input$pdf_page_size
      
      # Set page dimensions based on selection
      if (page_size == "A4") {
        page_width <- 210
        page_height <- 297
      } else {
        page_width <- 215.9
        page_height <- 279.4
      }
      
      # Show progress
      withProgress(message = 'Converting images to PDF...', value = 0, {
        
        results_list <- list()
        
        for (i in 1:nrow(files_to_convert)) {
          file_info <- files_to_convert[i, ]
          
          incProgress(1/nrow(files_to_convert), 
                      detail = paste("Converting", file_info$name))
          
          tryCatch({
            # Read image
            img <- magick::image_read(file_info$datapath)
            
            # Set DPI to 300 for high quality
            dpi_value <- 300
            
            # Calculate page dimensions at 300 DPI
            page_width_px <- page_width * dpi_value / 25.4
            page_height_px <- page_height * dpi_value / 25.4
            
            # Resize to fit within page dimensions while maintaining aspect ratio
            img <- magick::image_resize(img, 
                                        geometry = paste0(page_width_px, "x", page_height_px))
            
            # Create output filename
            base_name <- tools::file_path_sans_ext(file_info$name)
            output_filename <- paste0(base_name, ".pdf")
            output_path <- file.path(output_folder, output_filename)
            
            # Convert to PDF with 300 DPI
            magick::image_write(img, output_path, format = "pdf", density = 300)
            
            # Add to results
            results_list[[i]] <- data.frame(
              image_file = file_info$name,
              pdf_file = output_filename,
              page_size = page_size,
              status = "Success",
              stringsAsFactors = FALSE
            )
            
          }, error = function(e) {
            results_list[[i]] <- data.frame(
              image_file = file_info$name,
              pdf_file = "",
              page_size = page_size,
              status = paste("Error:", e$message),
              stringsAsFactors = FALSE
            )
          })
        }
        
        # Combine results
        if (length(results_list) > 0) {
          results_df <- do.call(rbind, results_list)
          rv$pdf_conversion_results <- results_df
        }
      })
      
      # Show success message
      if (!is.null(rv$pdf_conversion_results) && nrow(rv$pdf_conversion_results) > 0) {
        success_count <- sum(rv$pdf_conversion_results$status == "Success", na.rm = TRUE)
        total_count <- nrow(rv$pdf_conversion_results)
        error_count <- total_count - success_count
        
        output$pdf_conversion_status <- renderUI({
          if (error_count > 0) {
            tags$div(
              class = "alert alert-success",
              tags$strong("Completed! "),
              sprintf("Successfully converted %d image(s) to PDF. %d error(s) occurred.", 
                      success_count, error_count),
              tags$br(),
              tags$small(paste("PDF files saved to:", output_folder))
            )
          } else {
            tags$div(
              class = "alert alert-success",
              tags$strong("✓ Success! "),
              sprintf("Successfully converted all %d image(s) to PDF format (%s) at 300 DPI.", 
                      total_count, page_size),
              tags$br(),
              tags$small(paste("PDF files saved to:", output_folder))
            )
          }
        })
        
        showNotification(paste("Conversion complete!", success_count, "PDFs created"), type = "message", duration = 5)
      }
    })
    
    # Display PDF conversion results
    output$pdf_conversion_results_table <- DT::renderDataTable({
      req(rv$pdf_conversion_results)
      DT::datatable(
        rv$pdf_conversion_results,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = 'frtip'
        ),
        rownames = FALSE
      )
    })
    
  })
}
