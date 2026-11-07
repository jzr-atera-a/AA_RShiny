library(shiny)
library(shinyjs)
library(officer)
library(webshot2)
library(htmltools)
library(fs)
library(purrr)

# Configuration
SLIDE_WIDTH <- 1333
SLIDE_HEIGHT <- 750
ASPECT_RATIO <- "16:9"

ui <- fluidPage(
  useShinyjs(),
  
  tags$head(
    tags$style(HTML("
      body { background-color: #1a1a1a; color: #e0e0e0; }
      .main-container { max-width: 1400px; margin: 0 auto; padding: 20px; }
      .header { 
        background: linear-gradient(135deg, #2d5f8d 0%, #1e3a5f 100%);
        padding: 20px; 
        border-radius: 10px; 
        margin-bottom: 20px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.3);
      }
      .header h1 { color: #00ff00; margin: 0; font-size: 28px; }
      .header p { color: #b0b0b0; margin: 5px 0 0 0; }
      
      .control-panel {
        background: #2a2a2a;
        border: 1px solid #3a3a3a;
        border-radius: 8px;
        padding: 20px;
        margin-bottom: 20px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.2);
      }
      
      .preview-container {
        background: #000;
        border: 2px solid #00ff00;
        border-radius: 10px;
        padding: 10px;
        box-shadow: 0 4px 16px rgba(0,255,0,0.2);
      }
      
      .preview-info {
        background: #1e1e1e;
        border: 1px solid #3a3a3a;
        border-radius: 5px;
        padding: 15px;
        margin-bottom: 15px;
      }
      
      .info-badge {
        display: inline-block;
        background: #2d5f8d;
        color: #fff;
        padding: 5px 12px;
        border-radius: 4px;
        margin-right: 10px;
        font-weight: 600;
        font-size: 12px;
      }
      
      .btn-export {
        background: linear-gradient(135deg, #00ff00 0%, #00cc00 100%);
        color: #000;
        border: none;
        font-weight: 700;
        padding: 10px 24px;
        border-radius: 6px;
        font-size: 16px;
        margin-right: 10px;
        cursor: pointer;
        transition: all 0.3s;
      }
      
      .btn-export:hover {
        background: linear-gradient(135deg, #00cc00 0%, #009900 100%);
        transform: translateY(-2px);
        box-shadow: 0 4px 12px rgba(0,255,0,0.3);
      }
      
      .btn-secondary {
        background: linear-gradient(135deg, #ffc000 0%, #cc9900 100%);
        color: #000;
      }
      
      .btn-secondary:hover {
        background: linear-gradient(135deg, #cc9900 0%, #996600 100%);
      }
      
      .status-message {
        padding: 12px;
        border-radius: 6px;
        margin-top: 15px;
        font-weight: 600;
      }
      
      .status-success {
        background: rgba(0, 255, 0, 0.1);
        border: 1px solid #00ff00;
        color: #00ff00;
      }
      
      .status-error {
        background: rgba(255, 0, 0, 0.1);
        border: 1px solid #ff0000;
        color: #ff6666;
      }
      
      .status-processing {
        background: rgba(255, 192, 0, 0.1);
        border: 1px solid #ffc000;
        color: #ffc000;
      }
      
      #slide_preview {
        width: 100%;
        height: 750px;
        border: none;
        border-radius: 5px;
        background: #0c0f14;
      }
      
      select, input {
        background: #2a2a2a;
        color: #e0e0e0;
        border: 1px solid #3a3a3a;
        border-radius: 4px;
        padding: 8px;
      }
      
      label { font-weight: 600; color: #b0b0b0; }
    "))
  ),
  
  div(class = "main-container",
    # Header
    div(class = "header",
      h1("CAM Pathfinder Slide Export Tool"),
      p("Preview and export HTML slides to PowerPoint or PDF with guaranteed 16:9 aspect ratio")
    ),
    
    # Control Panel
    div(class = "control-panel",
      fluidRow(
        column(6,
          selectInput("selected_slide", 
                     "Select Slide to Preview:",
                     choices = NULL,
                     width = "100%")
        ),
        column(6,
          br(),
          actionButton("refresh_slides", "🔄 Refresh Slide List", 
                      class = "btn btn-secondary"),
          actionButton("prev_slide", "◀ Previous", 
                      style = "margin-left: 10px;"),
          actionButton("next_slide", "Next ▶")
        )
      )
    ),
    
    # Preview Info
    div(class = "preview-info",
      h4("Preview Information"),
      div(
        span(class = "info-badge", textOutput("slide_dimensions", inline = TRUE)),
        span(class = "info-badge", textOutput("aspect_ratio_info", inline = TRUE)),
        span(class = "info-badge", "PPTX Ready: ✓")
      )
    ),
    
    # Preview Container
    div(class = "preview-container",
      uiOutput("preview_frame")
    ),
    
    # Export Controls
    div(class = "control-panel", style = "margin-top: 20px;",
      h4("Export Options"),
      fluidRow(
        column(3,
          actionButton("export_single_pdf", "📄 Export to PDF", 
                      class = "btn-export"),
          br(), br(),
          checkboxInput("high_res_png", "High Resolution (2x DPI)", value = TRUE)
        ),
        column(3,
          actionButton("export_single_pptx", "📊 Export to PPTX", 
                      class = "btn-export"),
          br(), br(),
          helpText("Creates single-slide PPTX")
        ),
        column(3,
          actionButton("export_all_pptx", "📑 Export ALL to PPTX", 
                      class = "btn-export btn-secondary"),
          br(), br(),
          helpText("Exports all slides to one PPTX")
        ),
        column(3,
          downloadButton("download_result", "⬇ Download Last Export",
                        class = "btn-export btn-secondary"),
          br(), br(),
          textOutput("file_size_info")
        )
      ),
      
      # Status Messages
      uiOutput("status_message")
    )
  )
)

server <- function(input, output, session) {
  
  # Reactive values
  rv <- reactiveValues(
    slides = NULL,
    current_slide_index = 1,
    last_export = NULL,
    status = NULL
  )
  
  # Load slides on startup
  load_slides <- function() {
    slides_dir <- "./html_originals"
    html_files <- list.files(slides_dir, pattern = "^Slide_.*\\.html$", full.names = TRUE)
    
    if (length(html_files) == 0) return(NULL)
    
    slides <- data.frame(
      path = html_files,
      name = basename(html_files),
      number = as.integer(gsub(".*Slide_(\\d+).*", "\\1", basename(html_files))),
      stringsAsFactors = FALSE
    )
    
    slides <- slides[order(slides$number), ]
    return(slides)
  }
  
  observe({
    rv$slides <- load_slides()
    if (!is.null(rv$slides)) {
      choices <- setNames(rv$slides$path, rv$slides$name)
      updateSelectInput(session, "selected_slide", choices = choices)
    }
  })
  
  # Refresh slides
  observeEvent(input$refresh_slides, {
    rv$slides <- load_slides()
    if (!is.null(rv$slides)) {
      choices <- setNames(rv$slides$path, rv$slides$name)
      updateSelectInput(session, "selected_slide", choices = choices)
      rv$status <- list(type = "success", message = "✓ Slide list refreshed")
    }
  })
  
  # Navigation
  observeEvent(input$prev_slide, {
    if (!is.null(rv$slides)) {
      current_idx <- which(rv$slides$path == input$selected_slide)
      if (length(current_idx) > 0 && current_idx > 1) {
        updateSelectInput(session, "selected_slide", selected = rv$slides$path[current_idx - 1])
      }
    }
  })
  
  observeEvent(input$next_slide, {
    if (!is.null(rv$slides)) {
      current_idx <- which(rv$slides$path == input$selected_slide)
      if (length(current_idx) > 0 && current_idx < nrow(rv$slides)) {
        updateSelectInput(session, "selected_slide", selected = rv$slides$path[current_idx + 1])
      }
    }
  })
  
  # Preview frame
  output$preview_frame <- renderUI({
    req(input$selected_slide)
    tags$iframe(
      id = "slide_preview",
      src = input$selected_slide,
      width = "100%",
      height = "750px",
      style = "border: none; background: #0c0f14;"
    )
  })
  
  # Info displays
  output$slide_dimensions <- renderText({
    paste0(SLIDE_WIDTH, " × ", SLIDE_HEIGHT, "px")
  })
  
  output$aspect_ratio_info <- renderText({
    paste0("Aspect Ratio: ", ASPECT_RATIO)
  })
  
  # Export to PDF
  observeEvent(input$export_single_pdf, {
    req(input$selected_slide)
    
    rv$status <- list(type = "processing", message = "⏳ Exporting to PDF...")
    
    tryCatch({
      output_file <- tempfile(fileext = ".pdf")
      
      # Use webshot2 for high-quality PDF
      webshot2::webshot(
        url = input$selected_slide,
        file = output_file,
        vwidth = SLIDE_WIDTH,
        vheight = SLIDE_HEIGHT,
        zoom = if(input$high_res_png) 2 else 1
      )
      
      # Copy to outputs
      slide_name <- basename(input$selected_slide)
      final_path <- file.path("/mnt/user-data/outputs", 
                             gsub("\\.html$", ".pdf", slide_name))
      file.copy(output_file, final_path, overwrite = TRUE)
      
      rv$last_export <- final_path
      rv$status <- list(type = "success", 
                       message = paste0("✓ PDF exported successfully: ", basename(final_path)))
      
    }, error = function(e) {
      rv$status <- list(type = "error", 
                       message = paste0("✗ Export failed: ", e$message))
    })
  })
  
  # Export to single-slide PPTX
  observeEvent(input$export_single_pptx, {
    req(input$selected_slide)
    
    rv$status <- list(type = "processing", message = "⏳ Creating PowerPoint...")
    
    tryCatch({
      # Create temporary PNG
      temp_png <- tempfile(fileext = ".png")
      webshot2::webshot(
        url = input$selected_slide,
        file = temp_png,
        vwidth = SLIDE_WIDTH,
        vheight = SLIDE_HEIGHT,
        zoom = if(input$high_res_png) 2 else 1
      )
      
      # Create PPTX
      pptx <- read_pptx()
      pptx <- add_slide(pptx, layout = "Blank", master = "Office Theme")
      
      # Add image to fill slide
      pptx <- ph_with(pptx, 
                     external_img(temp_png, width = 13.33, height = 7.5),
                     location = ph_location_fullsize())
      
      # Save
      slide_name <- basename(input$selected_slide)
      output_path <- file.path("/mnt/user-data/outputs", 
                               gsub("\\.html$", ".pptx", slide_name))
      print(pptx, target = output_path)
      
      rv$last_export <- output_path
      rv$status <- list(type = "success", 
                       message = paste0("✓ PPTX created: ", basename(output_path)))
      
      unlink(temp_png)
      
    }, error = function(e) {
      rv$status <- list(type = "error", 
                       message = paste0("✗ PPTX export failed: ", e$message))
    })
  })
  
  # Export all slides to PPTX
  observeEvent(input$export_all_pptx, {
    req(rv$slides)
    
    rv$status <- list(type = "processing", 
                     message = paste0("⏳ Exporting ", nrow(rv$slides), " slides to PowerPoint..."))
    
    tryCatch({
      pptx <- read_pptx()
      temp_pngs <- c()
      
      # Convert each slide to PNG and add to PPTX
      for (i in 1:nrow(rv$slides)) {
        temp_png <- tempfile(fileext = ".png")
        
        webshot2::webshot(
          url = rv$slides$path[i],
          file = temp_png,
          vwidth = SLIDE_WIDTH,
          vheight = SLIDE_HEIGHT,
          zoom = if(input$high_res_png) 2 else 1
        )
        
        pptx <- add_slide(pptx, layout = "Blank", master = "Office Theme")
        pptx <- ph_with(pptx, 
                       external_img(temp_png, width = 13.33, height = 7.5),
                       location = ph_location_fullsize())
        
        temp_pngs <- c(temp_pngs, temp_png)
        
        # Update status
        rv$status <- list(type = "processing", 
                         message = paste0("⏳ Processing slide ", i, "/", nrow(rv$slides), "..."))
      }
      
      # Save complete presentation
      output_path <- file.path("/mnt/user-data/outputs", 
                               "CAM_Pathfinder_Complete_Presentation.pptx")
      print(pptx, target = output_path)
      
      rv$last_export <- output_path
      rv$status <- list(type = "success", 
                       message = paste0("✓ Complete presentation created with ", 
                                       nrow(rv$slides), " slides"))
      
      # Cleanup
      lapply(temp_pngs, unlink)
      
    }, error = function(e) {
      rv$status <- list(type = "error", 
                       message = paste0("✗ Batch export failed: ", e$message))
    })
  })
  
  # Status message display
  output$status_message <- renderUI({
    req(rv$status)
    
    class_name <- switch(rv$status$type,
      "success" = "status-message status-success",
      "error" = "status-message status-error",
      "processing" = "status-message status-processing",
      "status-message"
    )
    
    div(class = class_name, rv$status$message)
  })
  
  # Download handler
  output$download_result <- downloadHandler(
    filename = function() {
      if (!is.null(rv$last_export)) {
        basename(rv$last_export)
      } else {
        "export.pptx"
      }
    },
    content = function(file) {
      if (!is.null(rv$last_export) && file.exists(rv$last_export)) {
        file.copy(rv$last_export, file)
      }
    }
  )
  
  # File size info
  output$file_size_info <- renderText({
    if (!is.null(rv$last_export) && file.exists(rv$last_export)) {
      size_mb <- file.info(rv$last_export)$size / 1024 / 1024
      paste0("Size: ", round(size_mb, 2), " MB")
    } else {
      "No export yet"
    }
  })
}

shinyApp(ui = ui, server = server)
