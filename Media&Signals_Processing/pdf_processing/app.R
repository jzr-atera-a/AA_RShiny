# Load required libraries
library(shiny)
library(shinydashboard)
library(shinyFiles)
library(pdftools)
library(qpdf)
library(fs)
library(magick)

# Configure Shiny options for large file uploads
options(shiny.maxRequestSize = -1)  # Remove file size limit completely

# Limits for the PDF Text Extractor tab
MAX_EXTRACT_FILES <- 10
MAX_EXTRACT_FILE_SIZE_MB <- 20
MAX_EXTRACT_FILE_SIZE_BYTES <- MAX_EXTRACT_FILE_SIZE_MB * 1024 * 1024

# Standard page sizes (width x height, in inches, portrait orientation) for the
# Image to PDF tab. Rendered at IMG_TO_PDF_DPI dots-per-inch.
IMG_TO_PDF_DPI <- 300
STANDARD_PAGE_SIZES <- list(
  "Letter (8.5 x 11 in)"    = c(8.5, 11),
  "Legal (8.5 x 14 in)"     = c(8.5, 14),
  "Tabloid (11 x 17 in)"    = c(11, 17),
  "A3 (11.69 x 16.54 in)"   = c(11.69, 16.54),
  "A4 (8.27 x 11.69 in)"    = c(8.27, 11.69),
  "A5 (5.83 x 8.27 in)"     = c(5.83, 8.27),
  "A6 (4.13 x 5.83 in)"     = c(4.13, 5.83),
  "B5 (6.93 x 9.84 in)"     = c(6.93, 9.84)
)

# Extract up to n of the most dominant colors present in an image, as hex
# strings. Used for the Image to PDF tab's "sample image" color picker: the
# user uploads a reference image, we quantize it down to its n most common
# colors, and present them as selectable swatches for the page gap fill.
get_top_colors <- function(file_path, n = 5) {
  tryCatch({
    img <- magick::image_read(file_path)
    if(length(img) > 1) {
      img <- img[1]
    }
    # Flatten any transparency onto white so the sample reflects visible colors
    img <- magick::image_background(img, "white", flatten = TRUE)
    # Downscale for speed
    img_small <- magick::image_resize(img, "300x300>")
    # Reduce the image to (at most) its n most representative colors
    img_quant <- magick::image_quantize(img_small, max = n, colorspace = "srgb")
    
    raster_mat <- grDevices::as.raster(img_quant)
    colors <- as.vector(raster_mat)
    color_counts <- sort(table(colors), decreasing = TRUE)
    
    if(length(color_counts) == 0) {
      return(character(0))
    }
    
    top_n <- min(n, length(color_counts))
    names(color_counts)[1:top_n]
  }, error = function(e) {
    character(0)
  })
}

# Get available volumes for directory selection
tryCatch({
  volumes <- c(Home = fs::path_home(), getVolumes()())
}, error = function(e) {
  # Fallback if fs package or getVolumes fails
  volumes <- c(Home = path.expand("~"), Root = "/")
})

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "PDF Manager"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("PDF Splitter", tabName = "splitter", icon = icon("cut")),
      menuItem("PDF Merger", tabName = "merger", icon = icon("puzzle-piece")),
      menuItem("Text Extractor", tabName = "extractor", icon = icon("file-alt")),
      menuItem("Image to PDF", tabName = "img2pdf", icon = icon("images"))
    )
  ),
  
  dashboardBody(
    # Custom CSS styling
    tags$style(HTML("
      .skin-blue .main-header .navbar {
        background-color: #008A82 !important;
      }
      .skin-blue .main-header .logo {
        background-color: #002C3C !important;
      }
      .skin-blue .main-header .logo:hover {
        background-color: #008A82 !important;
      }
      .skin-blue .main-sidebar {
        background-color: #00A39A !important;
      }
      .skin-blue .sidebar-menu > li.header {
        background: #008A82 !important;
        color: white !important;
      }
      .skin-blue .sidebar-menu > li > a {
        color: white !important;
      }
      .skin-blue .sidebar-menu > li:hover > a,
      .skin-blue .sidebar-menu > li.active > a {
        background-color: #008A82 !important;
        color: white !important;
      }
      .content-wrapper, .right-side {
        background-color: #002C3C !important;
      }
      .box {
        background: #00A39A !important;
        border-top: none !important;
        color: white !important;
      }
      .box-header {
        background: #00A39A !important;
        color: white !important;
      }
      .box-body {
        background: white !important;
        color: #2c3e50 !important;
      }
      .box-title {
        color: white !important;
      }
      .metric-box {
        background: white;
        border-radius: 8px;
        padding: 15px;
        margin: 10px 0;
        border-left: 4px solid #00A39A;
        box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        color: #2c3e50 !important;
      }
      .form-control {
        background-color: rgba(255,255,255,0.9) !important;
        border: 1px solid #bdc3c7 !important;
        color: #2c3e50 !important;
      }
      .form-control:focus {
        border-color: #008A82 !important;
        box-shadow: 0 0 0 0.2rem rgba(0, 163, 154, 0.25) !important;
      }
      .info-box {
        background: #f8f9fa;
        border: 1px solid #dee2e6;
        border-radius: 8px;
        padding: 15px;
        margin: 20px 0;
        font-size: 0.9em;
        color: #495057;
      }
      .info-box h5 {
        color: #00A39A;
        margin-bottom: 10px;
        font-weight: bold;
      }
      .btn-primary {
        background-color: #008A82 !important;
        border-color: #008A82 !important;
      }
      .btn-primary:hover {
        background-color: #00A39A !important;
        border-color: #00A39A !important;
      }
      .directory-display {
        background-color: #f8f9fa;
        border: 1px solid #dee2e6;
        border-radius: 4px;
        padding: 10px;
        min-height: 40px;
        font-family: monospace;
        color: #495057;
        word-break: break-all;
      }
    ")),
    
    tabItems(
      # PDF Splitter Tab
      tabItem(tabName = "splitter",
              fluidRow(
                box(
                  title = "PDF Splitter Configuration", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(6,
                           h4("Input PDF File"),
                           fileInput("input_pdf", "Select PDF File:",
                                     accept = c(".pdf"),
                                     placeholder = "No file selected")
                    ),
                    column(6,
                           h4("Split Configuration"),
                           numericInput("num_parts", "Number of Parts:",
                                        value = 2, min = 2, max = 20, step = 1)
                    )
                  ),
                  
                  fluidRow(
                    column(12,
                           h4("Output Directory"),
                           fluidRow(
                             column(9,
                                    div(class = "directory-display",
                                        textOutput("selected_output_dir"))
                             ),
                             column(3,
                                    shinyDirButton("output_dir_select", "Browse", 
                                                   "Select output directory", 
                                                   class = "btn-primary",
                                                   style = "width: 100%;")
                             )
                           )
                    )
                  ),
                  
                  hr(),
                  
                  fluidRow(
                    column(6,
                           actionButton("analyze_pdf", "Analyze PDF", 
                                        class = "btn-primary btn-lg",
                                        style = "width: 100%;")
                    ),
                    column(6,
                           actionButton("split_pdf", "Split PDF", 
                                        class = "btn-primary btn-lg",
                                        style = "width: 100%;")
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "PDF Analysis Results", 
                  status = "info", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "info-box",
                      verbatimTextOutput("pdf_info")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Split Preview", 
                  status = "info", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "info-box",
                      verbatimTextOutput("split_preview")
                  )
                )
              )
      ),
      
      # PDF Merger Tab
      tabItem(tabName = "merger",
              fluidRow(
                box(
                  title = "PDF Merger Configuration", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  h4("Select PDF Files to Merge"),
                  p("Upload PDF files in the order you want them merged.", 
                    style = "color: #6c757d; font-style: italic;"),
                  
                  fluidRow(
                    column(6,
                           fileInput("merge_pdf1", "PDF File 1:",
                                     accept = c(".pdf")),
                           fileInput("merge_pdf3", "PDF File 3:",
                                     accept = c(".pdf")),
                           fileInput("merge_pdf5", "PDF File 5:",
                                     accept = c(".pdf"))
                    ),
                    column(6,
                           fileInput("merge_pdf2", "PDF File 2:",
                                     accept = c(".pdf")),
                           fileInput("merge_pdf4", "PDF File 4:",
                                     accept = c(".pdf"))
                    )
                  ),
                  
                  hr(),
                  
                  fluidRow(
                    column(6,
                           h4("Output File"),
                           textInput("merge_filename", "Output Filename:",
                                     placeholder = "merged_document.pdf",
                                     value = "merged_document.pdf")
                    ),
                    column(6,
                           h4("Output Directory"),
                           fluidRow(
                             column(9,
                                    div(class = "directory-display",
                                        textOutput("selected_merge_dir"))
                             ),
                             column(3,
                                    br(),
                                    shinyDirButton("merge_dir_select", "Browse", 
                                                   "Select output directory", 
                                                   class = "btn-primary",
                                                   style = "width: 100%;")
                             )
                           )
                    )
                  ),
                  
                  br(),
                  
                  fluidRow(
                    column(12,
                           actionButton("merge_pdfs", "Merge PDFs", 
                                        class = "btn-primary btn-lg",
                                        style = "width: 100%;")
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Selected Files Summary", 
                  status = "info", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "info-box",
                      verbatimTextOutput("merge_summary")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Merge Status", 
                  status = "info", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "info-box",
                      verbatimTextOutput("merge_status")
                  )
                )
              )
      ),
      
      # PDF Text Extractor Tab
      tabItem(tabName = "extractor",
              fluidRow(
                box(
                  title = "PDF Text Extractor Configuration", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  h4("Select PDF Files"),
                  p("Select up to 10 PDF files (max 20 MB each). Text will be extracted from each and combined into a single .txt file, with each file's content under a header showing its filename. Images are ignored; embedded text (including most mathematical text/symbols) is extracted as-is.", 
                    style = "color: #6c757d; font-style: italic;"),
                  
                  fileInput("extract_pdfs", "Select PDF Files (up to 10):",
                            accept = c(".pdf"),
                            multiple = TRUE,
                            placeholder = "No files selected"),
                  
                  hr(),
                  
                  fluidRow(
                    column(9,
                           div(class = "directory-display",
                               textOutput("selected_extract_save_path"))
                    ),
                    column(3,
                           shinySaveButton("extract_save_select", "Choose Save Location & Name",
                                           "Save extracted text as...",
                                           filetype = list(txt = "txt"),
                                           class = "btn-primary",
                                           style = "width: 100%;")
                    )
                  ),
                  
                  br(),
                  
                  fluidRow(
                    column(12,
                           actionButton("extract_text_btn", "Extract Text & Save",
                                        class = "btn-primary btn-lg",
                                        style = "width: 100%;")
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Selected Files Summary", 
                  status = "info", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "info-box",
                      verbatimTextOutput("extract_files_summary")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Extraction Status", 
                  status = "info", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "info-box",
                      verbatimTextOutput("extract_status")
                  )
                )
              )
      ),
      
      # Image to PDF Tab
      tabItem(tabName = "img2pdf",
              fluidRow(
                box(
                  title = "Image to PDF Configuration", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  h4("Select Image Files"),
                  p("Select several JPEG, PNG, or GIF images (ideally of similar size) to combine into a single multi-page PDF, one image per page. Files are automatically ordered by their timestamp (oldest first) - handy for screenshot sequences regardless of the order they were selected in. Animated GIFs use only their first frame. PNG screenshots with transparent backgrounds are flattened onto a white background so they display correctly.", 
                    style = "color: #6c757d; font-style: italic;"),
                  
                  fileInput("img_files", "Select Image Files (JPEG / PNG / GIF):",
                            accept = c(".jpg", ".jpeg", ".png", ".gif"),
                            multiple = TRUE,
                            placeholder = "No files selected"),
                  
                  # Capture each file's original last-modified timestamp via the browser's
                  # File API (not exposed by fileInput by default), so the server can sort
                  # images chronologically instead of relying on browser selection order.
                  tags$script(HTML("
                    $(document).on('change', '#img_files', function(evt) {
                      var files = evt.target.files;
                      var timestamps = [];
                      for (var i = 0; i < files.length; i++) {
                        timestamps.push(files[i].lastModified);
                      }
                      Shiny.setInputValue('img_files_timestamps', timestamps, {priority: 'event'});
                    });
                  ")),
                  
                  hr(),
                  
                  fluidRow(
                    column(4,
                           h4("Page Size"),
                           selectInput("img_page_size", "Standard Page Size:",
                                       choices = names(STANDARD_PAGE_SIZES),
                                       selected = "Letter (8.5 x 11 in)")
                    ),
                    column(4,
                           h4("Page Orientation"),
                           selectInput("img_orientation", "Orientation:",
                                       choices = c("Portrait (Vertical)" = "Portrait",
                                                   "Landscape (Horizontal)" = "Landscape"),
                                       selected = "Portrait")
                    ),
                    column(4,
                           h4("Image Rotation"),
                           selectInput("img_rotation", "Rotate Each Image:",
                                       choices = c("0 degrees" = "0",
                                                   "90 degrees" = "90",
                                                   "180 degrees" = "180",
                                                   "270 degrees" = "270"),
                                       selected = "0")
                    )
                  ),
                  
                  hr(),
                  
                  fluidRow(
                    column(12,
                           h4("Page Background / Gap Fill Color"),
                           p("If an image's proportions don't perfectly match the selected page size, the leftover space around it can be filled with a color instead of white. Optionally select a sample JPEG, PNG, or GIF below to extract its 5 most dominant colors, then check one swatch to use it as the fill for every page. Leave none checked to keep the gaps white (default).",
                             style = "color: #6c757d; font-style: italic; margin-bottom: 10px;"),
                           fileInput("color_sample_file", "Select Sample Image for Color Palette (optional):",
                                     accept = c(".jpg", ".jpeg", ".png", ".gif"),
                                     multiple = FALSE,
                                     placeholder = "No sample image selected"),
                           uiOutput("color_palette_ui")
                    )
                  ),
                  
                  hr(),
                  
                  fluidRow(
                    column(6,
                           h4("Output File"),
                           textInput("img_pdf_filename", "PDF Filename:",
                                     placeholder = "combined_images.pdf",
                                     value = "combined_images.pdf")
                    ),
                    column(6,
                           h4("Output Directory"),
                           fluidRow(
                             column(9,
                                    div(class = "directory-display",
                                        textOutput("selected_img_pdf_dir"))
                             ),
                             column(3,
                                    br(),
                                    shinyDirButton("img_pdf_dir_select", "Browse", 
                                                   "Select output directory", 
                                                   class = "btn-primary",
                                                   style = "width: 100%;")
                             )
                           )
                    )
                  ),
                  
                  br(),
                  
                  fluidRow(
                    column(12,
                           actionButton("create_img_pdf_btn", "Create PDF from Images", 
                                        class = "btn-primary btn-lg",
                                        style = "width: 100%;")
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Selected Images Summary", 
                  status = "info", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "info-box",
                      verbatimTextOutput("img_files_summary")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "PDF Creation Status", 
                  status = "info", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "info-box",
                      verbatimTextOutput("img_pdf_status")
                  )
                )
              )
      )
    )
  ),
  
  skin = "blue"
)

# Define Server
server <- function(input, output, session) {
  
  # Configure directory choosers with proper roots
  shinyDirChoose(input, "output_dir_select", roots = volumes, session = session, restrictions = system.file(package = "base"))
  shinyDirChoose(input, "merge_dir_select", roots = volumes, session = session, restrictions = system.file(package = "base"))
  shinyFileSave(input, "extract_save_select", roots = volumes, session = session,
                filetype = list(txt = "txt"), restrictions = system.file(package = "base"))
  shinyDirChoose(input, "img_pdf_dir_select", roots = volumes, session = session, restrictions = system.file(package = "base"))
  
  # Reactive values
  values <- reactiveValues(
    pdf_pages = NULL,
    pdf_name = NULL,
    split_plan = NULL,
    output_directory = NULL,
    merge_directory = NULL,
    merge_status_text = "Ready to merge PDFs. Select at least 2 files and output path, then click 'Merge PDFs'.",
    extract_save_path = NULL,
    extract_status_text = "Select PDF files, choose a save location & filename, then click 'Extract Text & Save'.",
    img_pdf_directory = NULL,
    img_pdf_status_text = "Select image files, page size, orientation, rotation, and output path, then click 'Create PDF from Images'.",
    color_palette = character(0)
  )
  
  # Directory selection observer for splitter
  observe({
    if(!is.null(input$output_dir_select) && !is.integer(input$output_dir_select)) {
      tryCatch({
        selected_path <- parseDirPath(volumes, input$output_dir_select)
        if(length(selected_path) > 0 && selected_path != "") {
          values$output_directory <- as.character(selected_path)
          showNotification("Output directory selected successfully!", type = "message", duration = 2)
        }
      }, error = function(e) {
        showNotification(paste("Error selecting directory:", e$message), type = "warning")
      })
    }
  })
  
  # Directory selection observer for merger
  observe({
    if(!is.null(input$merge_dir_select) && !is.integer(input$merge_dir_select)) {
      tryCatch({
        selected_path <- parseDirPath(volumes, input$merge_dir_select)
        if(length(selected_path) > 0 && selected_path != "") {
          values$merge_directory <- as.character(selected_path)
          showNotification("Output directory selected successfully!", type = "message", duration = 2)
        }
      }, error = function(e) {
        showNotification(paste("Error selecting directory:", e$message), type = "warning")
      })
    }
  })
  
  # Display selected directories
  output$selected_output_dir <- renderText({
    if(is.null(values$output_directory) || length(values$output_directory) == 0) {
      "No directory selected - Click 'Browse' to select"
    } else {
      values$output_directory
    }
  })
  
  output$selected_merge_dir <- renderText({
    if(is.null(values$merge_directory) || length(values$merge_directory) == 0) {
      "No directory selected - Click 'Browse' to select"
    } else {
      values$merge_directory
    }
  })
  
  # PDF Splitter Logic
  observeEvent(input$analyze_pdf, {
    req(input$input_pdf)
    
    showNotification("Analyzing PDF... Please wait.", 
                     type = "message", duration = NULL, id = "analyzing_pdf")
    
    values$pdf_pages <- NULL
    values$pdf_name <- NULL
    values$split_plan <- NULL
    
    tryCatch({
      if(is.null(input$input_pdf) || is.null(input$input_pdf$datapath)) {
        stop("No PDF file selected or file path is invalid")
      }
      
      pdf_path <- input$input_pdf$datapath
      
      if(!file.exists(pdf_path)) {
        stop("PDF file does not exist at the specified path")
      }
      
      file_size <- file.size(pdf_path)
      if(is.na(file_size) || file_size == 0) {
        stop("PDF file is empty or cannot be read")
      }
      
      # Get page count
      pdf_pages_count <- NULL
      
      tryCatch({
        pdf_pages_count <- pdf_length(pdf_path)
        if(!is.null(pdf_pages_count) && length(pdf_pages_count) > 0 && !is.na(pdf_pages_count) && pdf_pages_count > 0) {
          values$pdf_pages <- pdf_pages_count
        } else {
          pdf_pages_count <- NULL
        }
      }, error = function(e1) {
        pdf_pages_count <- NULL
      })
      
      if(is.null(pdf_pages_count)) {
        tryCatch({
          pdf_info_result <- pdf_info(pdf_path)
          if(!is.null(pdf_info_result) && is.data.frame(pdf_info_result) && nrow(pdf_info_result) > 0) {
            values$pdf_pages <- nrow(pdf_info_result)
          } else {
            stop("PDF info returned empty results")
          }
        }, error = function(e2) {
          stop("Unable to analyze PDF - file may be corrupted, password protected, or in an unsupported format")
        })
      }
      
      if(is.null(values$pdf_pages) || length(values$pdf_pages) == 0 || is.na(values$pdf_pages) || values$pdf_pages <= 0) {
        stop("Could not determine valid page count for PDF")
      }
      
      pdf_filename <- input$input_pdf$name
      values$pdf_name <- tools::file_path_sans_ext(pdf_filename)
      
      if(is.null(values$pdf_name) || length(values$pdf_name) == 0 || values$pdf_name == "") {
        values$pdf_name <- paste0("document_", format(Sys.time(), "%Y%m%d_%H%M%S"))
      }
      
      total_pages <- as.numeric(values$pdf_pages)
      num_parts <- as.numeric(input$num_parts)
      
      if(total_pages < num_parts) {
        showNotification(paste("Warning: PDF has only", total_pages, "pages but you requested", num_parts, "parts. Adjusting to", total_pages, "parts."), type = "warning")
        num_parts <- total_pages
      }
      
      pages_per_part <- ceiling(total_pages / num_parts)
      
      split_plan <- data.frame(
        Part = 1:num_parts,
        Start_Page = numeric(num_parts),
        End_Page = numeric(num_parts),
        Pages_Count = numeric(num_parts),
        stringsAsFactors = FALSE
      )
      
      for(i in 1:num_parts) {
        start_page <- (i - 1) * pages_per_part + 1
        end_page <- min(i * pages_per_part, total_pages)
        
        split_plan$Start_Page[i] <- start_page
        split_plan$End_Page[i] <- end_page
        split_plan$Pages_Count[i] <- end_page - start_page + 1
      }
      
      values$split_plan <- split_plan
      
      removeNotification("analyzing_pdf")
      showNotification(paste("PDF analysis completed! Found", total_pages, "pages."), type = "message")
      
    }, error = function(e) {
      values$pdf_pages <- NULL
      values$pdf_name <- NULL
      values$split_plan <- NULL
      
      removeNotification("analyzing_pdf")
      
      error_msg <- as.character(e$message)
      if(length(error_msg) == 0 || error_msg == "") {
        error_msg <- "Unknown error occurred while analyzing PDF"
      }
      
      showNotification(paste("Error analyzing PDF:", error_msg), type = "error", duration = 10)
    })
  })
  
  output$pdf_info <- renderText({
    if(is.null(values$pdf_pages)) {
      "No PDF analyzed yet. Please select a PDF file and click 'Analyze PDF'."
    } else {
      paste0("PDF File: ", input$input_pdf$name, "\n",
             "Total Pages: ", values$pdf_pages, "\n",
             "Requested Parts: ", input$num_parts)
    }
  })
  
  output$split_preview <- renderText({
    if(is.null(values$split_plan)) {
      "Analysis required before preview."
    } else {
      preview_text <- "Split Plan:\n\n"
      for(i in 1:nrow(values$split_plan)) {
        part_name <- paste0(values$pdf_name, "_part", i, ".pdf")
        preview_text <- paste0(preview_text,
                               "Part ", i, ": ", part_name, "\n",
                               "  Pages: ", values$split_plan$Start_Page[i], 
                               " to ", values$split_plan$End_Page[i],
                               " (", values$split_plan$Pages_Count[i], " pages)\n\n")
      }
      preview_text
    }
  })
  
  observeEvent(input$split_pdf, {
    req(input$input_pdf, values$split_plan)
    
    if(is.null(values$output_directory) || length(values$output_directory) == 0 || values$output_directory == "") {
      showNotification("Please select an output directory first.", type = "warning")
      return()
    }
    
    showNotification("Processing PDF... This may take a while for large files.", 
                     type = "message", duration = NULL, id = "processing_split")
    
    tryCatch({
      pdf_path <- input$input_pdf$datapath
      output_dir <- values$output_directory
      
      if(!dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE)
      }
      
      valid_parts <- which(!is.na(values$split_plan$Start_Page))
      
      for(i in valid_parts) {
        start_page <- values$split_plan$Start_Page[i]
        end_page <- values$split_plan$End_Page[i]
        output_file <- file.path(output_dir, paste0(values$pdf_name, "_part", i, ".pdf"))
        
        qpdf::pdf_subset(pdf_path, pages = start_page:end_page, output = output_file)
        
        showNotification(paste("Completed part", i, "of", length(valid_parts)), 
                         type = "message", duration = 2)
      }
      
      removeNotification("processing_split")
      
      showNotification(paste("PDF successfully split into", length(valid_parts), "parts!"), 
                       type = "message", duration = 5)
      
    }, error = function(e) {
      removeNotification("processing_split")
      showNotification(paste("Error splitting PDF:", e$message), type = "error", duration = 10)
    })
  })
  
  # PDF Merger Logic
  output$merge_summary <- renderText({
    files <- list(
      input$merge_pdf1, input$merge_pdf2, input$merge_pdf3, 
      input$merge_pdf4, input$merge_pdf5
    )
    
    selected_files <- Filter(function(x) !is.null(x), files)
    
    if(length(selected_files) == 0) {
      "No PDF files selected for merging.\n\nPlease upload at least 2 PDF files in the order you want them merged."
    } else {
      summary_text <- paste0("Selected Files (", length(selected_files), "):\n\n")
      for(i in 1:length(selected_files)) {
        file_info <- selected_files[[i]]
        file_size <- round(file.size(file_info$datapath) / 1024 / 1024, 2)
        summary_text <- paste0(summary_text, i, ". ", file_info$name, 
                               " (", file_size, " MB)\n")
      }
      
      if(length(selected_files) < 2) {
        summary_text <- paste0(summary_text, "\n⚠ Please select at least 2 files to merge.")
      }
      
      summary_text
    }
  })
  
  observeEvent(input$merge_pdfs, {
    # Get all selected files
    files <- list(
      input$merge_pdf1, input$merge_pdf2, input$merge_pdf3, 
      input$merge_pdf4, input$merge_pdf5
    )
    
    selected_files <- Filter(function(x) !is.null(x), files)
    
    # Validation checks
    if(length(selected_files) < 2) {
      showNotification("Please select at least 2 PDF files to merge.", type = "warning", duration = 5)
      values$merge_status_text <- "❌ Error: At least 2 PDF files are required for merging."
      return()
    }
    
    if(is.null(values$merge_directory) || length(values$merge_directory) == 0 || values$merge_directory == "") {
      showNotification("Please select an output directory first.", type = "warning", duration = 5)
      values$merge_status_text <- "❌ Error: No output directory selected. Click 'Browse' to select one."
      return()
    }
    
    if(is.null(input$merge_filename) || input$merge_filename == "" || trimws(input$merge_filename) == "") {
      showNotification("Please specify an output filename.", type = "warning", duration = 5)
      values$merge_status_text <- "❌ Error: No output filename specified."
      return()
    }
    
    # Show processing notification
    showNotification("Merging PDFs... This may take a while for large files.", 
                     type = "message", duration = NULL, id = "processing_merge")
    
    values$merge_status_text <- paste0("Processing ", length(selected_files), " PDF files...")
    
    tryCatch({
      # Get file paths
      file_paths <- sapply(selected_files, function(x) x$datapath)
      
      # Validate all files exist
      for(i in 1:length(file_paths)) {
        if(!file.exists(file_paths[i])) {
          stop(paste("File", i, "does not exist or cannot be accessed"))
        }
      }
      
      # Create full output path
      output_filename <- trimws(input$merge_filename)
      if(!grepl("\\.pdf$", output_filename, ignore.case = TRUE)) {
        output_filename <- paste0(output_filename, ".pdf")
      }
      output_path <- file.path(values$merge_directory, output_filename)
      
      # Create output directory if it doesn't exist
      if(!dir.exists(values$merge_directory)) {
        dir.create(values$merge_directory, recursive = TRUE)
      }
      
      # Check if output file already exists
      if(file.exists(output_path)) {
        showNotification("Warning: Output file already exists and will be overwritten.", 
                         type = "warning", duration = 3)
      }
      
      # Merge PDFs using qpdf
      qpdf::pdf_combine(input = file_paths, output = output_path)
      
      # Verify the output file was created
      if(!file.exists(output_path)) {
        stop("Merge appeared to complete but output file was not created")
      }
      
      output_size <- round(file.size(output_path) / 1024 / 1024, 2)
      
      # Remove processing notification
      removeNotification("processing_merge")
      
      success_msg <- paste0("✅ Successfully merged ", length(selected_files), 
                            " PDF files!\n\nOutput: ", basename(output_path), 
                            " (", output_size, " MB)\nLocation: ", values$merge_directory)
      
      values$merge_status_text <- success_msg
      
      showNotification(paste("PDFs successfully merged into:", basename(output_path)), 
                       type = "message", duration = 5)
      
    }, error = function(e) {
      removeNotification("processing_merge")
      
      error_msg <- paste0("❌ Error merging PDFs:\n", e$message)
      values$merge_status_text <- error_msg
      
      showNotification(paste("Error merging PDFs:", e$message), type = "error", duration = 10)
    })
  })
  
  output$merge_status <- renderText({
    values$merge_status_text
  })
  
  # PDF Text Extractor Logic
  
  # Track chosen save path (name + location) from the native Save As dialog
  observe({
    if(!is.null(input$extract_save_select) && !is.integer(input$extract_save_select)) {
      tryCatch({
        fileinfo <- parseSavePath(volumes, input$extract_save_select)
        if(nrow(fileinfo) > 0) {
          save_path <- as.character(fileinfo$datapath[1])
          if(!grepl("\\.txt$", save_path, ignore.case = TRUE)) {
            save_path <- paste0(save_path, ".txt")
          }
          values$extract_save_path <- save_path
          showNotification("Save location selected successfully!", type = "message", duration = 2)
        }
      }, error = function(e) {
        showNotification(paste("Error selecting save location:", e$message), type = "warning")
      })
    }
  })
  
  output$selected_extract_save_path <- renderText({
    if(is.null(values$extract_save_path) || length(values$extract_save_path) == 0) {
      "No save location selected - Click 'Choose Save Location & Name'"
    } else {
      values$extract_save_path
    }
  })
  
  # Summary of currently selected PDF files, with validation warnings
  output$extract_files_summary <- renderText({
    if(is.null(input$extract_pdfs)) {
      "No PDF files selected yet. Please select up to 10 PDF files (max 20 MB each)."
    } else {
      files_df <- input$extract_pdfs
      n_files <- nrow(files_df)
      
      summary_text <- paste0("Selected Files (", n_files, "):\n\n")
      for(i in 1:n_files) {
        file_size_mb <- round(files_df$size[i] / 1024 / 1024, 2)
        oversized <- files_df$size[i] > MAX_EXTRACT_FILE_SIZE_BYTES
        summary_text <- paste0(summary_text, i, ". ", files_df$name[i],
                               " (", file_size_mb, " MB)",
                               if(oversized) paste0("  ⚠ EXCEEDS ", MAX_EXTRACT_FILE_SIZE_MB, " MB LIMIT") else "",
                               "\n")
      }
      
      if(n_files > MAX_EXTRACT_FILES) {
        summary_text <- paste0(summary_text, "\n⚠ You selected ", n_files,
                               " files. Only the first ", MAX_EXTRACT_FILES,
                               " will be processed - please re-select ", MAX_EXTRACT_FILES,
                               " or fewer files.")
      }
      
      any_oversized <- any(files_df$size > MAX_EXTRACT_FILE_SIZE_BYTES)
      if(any_oversized) {
        summary_text <- paste0(summary_text, "\n⚠ One or more files exceed the ",
                               MAX_EXTRACT_FILE_SIZE_MB, " MB limit and will be skipped during extraction.")
      }
      
      summary_text
    }
  })
  
  observeEvent(input$extract_text_btn, {
    req(input$extract_pdfs)
    
    if(is.null(values$extract_save_path) || length(values$extract_save_path) == 0 || values$extract_save_path == "") {
      showNotification("Please choose a save location and filename first.", type = "warning", duration = 5)
      values$extract_status_text <- "❌ Error: No save location selected. Click 'Choose Save Location & Name'."
      return()
    }
    
    files_df <- input$extract_pdfs
    
    if(nrow(files_df) > MAX_EXTRACT_FILES) {
      showNotification(paste("Please select", MAX_EXTRACT_FILES, "or fewer PDF files."), type = "warning", duration = 5)
      values$extract_status_text <- paste0("❌ Error: ", nrow(files_df), " files selected. Maximum is ", MAX_EXTRACT_FILES, ".")
      return()
    }
    
    showNotification("Extracting text from PDFs... This may take a while for large files.",
                     type = "message", duration = NULL, id = "processing_extract")
    values$extract_status_text <- paste0("Processing ", nrow(files_df), " PDF file(s)...")
    
    tryCatch({
      output_dir <- dirname(values$extract_save_path)
      if(!dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE)
      }
      
      combined_parts <- character(0)
      processed_count <- 0
      skipped_files <- character(0)
      
      withProgress(message = "Extracting PDF text", value = 0, {
        n_files <- nrow(files_df)
        
        for(i in 1:n_files) {
          file_name <- files_df$name[i]
          file_path <- files_df$datapath[i]
          file_size <- files_df$size[i]
          
          incProgress(1 / n_files, detail = paste("Processing", file_name))
          
          if(file_size > MAX_EXTRACT_FILE_SIZE_BYTES) {
            skipped_files <- c(skipped_files, paste0(file_name, " (exceeds ", MAX_EXTRACT_FILE_SIZE_MB, " MB limit)"))
            next
          }
          
          file_section <- tryCatch({
            if(!file.exists(file_path)) {
              stop("File does not exist or cannot be accessed")
            }
            
            pages_text <- pdftools::pdf_text(file_path)
            
            if(is.null(pages_text) || length(pages_text) == 0) {
              stop("No extractable text found in this PDF")
            }
            
            page_blocks <- character(length(pages_text))
            for(p in seq_along(pages_text)) {
              page_blocks[p] <- paste0("--- Page ", p, " ---\n", pages_text[p])
            }
            
            full_text <- paste(page_blocks, collapse = "\n\n")
            
            paste0(strrep("=", 70), "\n",
                   "FILE: ", file_name, "\n",
                   strrep("=", 70), "\n\n",
                   full_text)
            
          }, error = function(e) {
            skipped_files <<- c(skipped_files, paste0(file_name, " (error: ", e$message, ")"))
            paste0(strrep("=", 70), "\n",
                   "FILE: ", file_name, "\n",
                   strrep("=", 70), "\n\n",
                   "[ERROR: Could not extract text from this file - ", e$message, "]")
          })
          
          combined_parts <- c(combined_parts, file_section)
          processed_count <- processed_count + 1
        }
      })
      
      if(length(combined_parts) == 0) {
        stop("No files could be processed. All files were skipped or exceeded the size limit.")
      }
      
      final_content <- paste(combined_parts, collapse = "\n\n\n")
      
      con <- file(values$extract_save_path, open = "w", encoding = "UTF-8")
      writeLines(final_content, con, useBytes = TRUE)
      close(con)
      
      removeNotification("processing_extract")
      
      status_msg <- paste0("✅ Successfully extracted text from ", processed_count, " of ", nrow(files_df), " file(s)!\n\n",
                           "Output: ", basename(values$extract_save_path), "\n",
                           "Location: ", values$extract_save_path)
      
      if(length(skipped_files) > 0) {
        status_msg <- paste0(status_msg, "\n\n⚠ Skipped/problem files:\n",
                             paste0("- ", skipped_files, collapse = "\n"))
      }
      
      values$extract_status_text <- status_msg
      
      showNotification(paste("Text extracted and saved to:", basename(values$extract_save_path)),
                       type = "message", duration = 5)
      
    }, error = function(e) {
      removeNotification("processing_extract")
      
      error_msg <- paste0("❌ Error extracting text:\n", e$message)
      values$extract_status_text <- error_msg
      
      showNotification(paste("Error extracting text:", e$message), type = "error", duration = 10)
    })
  })
  
  output$extract_status <- renderText({
    values$extract_status_text
  })
  
  # Image to PDF Logic
  
  # Directory selection observer for image-to-pdf output
  observe({
    if(!is.null(input$img_pdf_dir_select) && !is.integer(input$img_pdf_dir_select)) {
      tryCatch({
        selected_path <- parseDirPath(volumes, input$img_pdf_dir_select)
        if(length(selected_path) > 0 && selected_path != "") {
          values$img_pdf_directory <- as.character(selected_path)
          showNotification("Output directory selected successfully!", type = "message", duration = 2)
        }
      }, error = function(e) {
        showNotification(paste("Error selecting directory:", e$message), type = "warning")
      })
    }
  })
  
  output$selected_img_pdf_dir <- renderText({
    if(is.null(values$img_pdf_directory) || length(values$img_pdf_directory) == 0) {
      "No directory selected - Click 'Browse' to select"
    } else {
      values$img_pdf_directory
    }
  })
  
  # Selected image files, sorted chronologically by their original last-modified
  # timestamp (oldest first) rather than browser selection order. Falls back to
  # the browser's original order if timestamps weren't captured for any reason.
  img_files_sorted <- reactive({
    req(input$img_files)
    files_df <- input$img_files
    ts <- input$img_files_timestamps
    
    if(!is.null(ts) && length(ts) == nrow(files_df)) {
      files_df$timestamp_ms <- as.numeric(ts)
      files_df <- files_df[order(files_df$timestamp_ms), ]
      rownames(files_df) <- NULL
    } else {
      files_df$timestamp_ms <- NA_real_
    }
    
    files_df
  })
  
  # Summary of currently selected image files
  output$img_files_summary <- renderText({
    if(is.null(input$img_files)) {
      "No image files selected yet. Please select JPEG, PNG, or GIF images to combine."
    } else {
      files_df <- img_files_sorted()
      n_files <- nrow(files_df)
      timestamps_available <- !all(is.na(files_df$timestamp_ms))
      
      summary_text <- paste0("Selected Images (", n_files, ") - ",
                             if(timestamps_available) "sorted oldest to newest, this is the order they'll appear in the PDF:\n\n"
                             else "timestamps unavailable, using browser selection order:\n\n")
      for(i in 1:n_files) {
        file_size_mb <- round(files_df$size[i] / 1024 / 1024, 2)
        timestamp_str <- if(!is.na(files_df$timestamp_ms[i])) {
          paste0(" - ", format(as.POSIXct(files_df$timestamp_ms[i] / 1000, origin = "1970-01-01", tz = Sys.timezone()),
                               "%Y-%m-%d %H:%M:%S"))
        } else {
          ""
        }
        summary_text <- paste0(summary_text, i, ". ", files_df$name[i],
                               " (", file_size_mb, " MB)", timestamp_str, "\n")
      }
      
      summary_text
    }
  })
  
  # Extract a color palette whenever a new sample image is uploaded
  observeEvent(input$color_sample_file, {
    req(input$color_sample_file)
    
    showNotification("Extracting dominant colors from sample image...",
                     type = "message", duration = 2, id = "extracting_palette")
    
    palette <- get_top_colors(input$color_sample_file$datapath, n = 5)
    
    removeNotification("extracting_palette")
    
    if(length(palette) == 0) {
      values$color_palette <- character(0)
      showNotification("Could not extract colors from that image.", type = "warning", duration = 5)
    } else {
      values$color_palette <- palette
      # Reset any previous swatch selection since the palette just changed
      updateCheckboxGroupInput(session, "fill_color_checkboxes", selected = character(0))
    }
  })
  
  # Render the extracted colors as clickable swatch checkboxes
  output$color_palette_ui <- renderUI({
    if(length(values$color_palette) == 0) {
      return(p("No sample image processed yet - gaps will be filled with white.",
                style = "color: #6c757d; font-style: italic;"))
    }
    
    choice_names <- lapply(values$color_palette, function(hex) {
      tagList(
        span(style = paste0("display:inline-block; width:24px; height:24px; ",
                            "background-color:", hex, "; border:1px solid #333; ",
                            "vertical-align:middle; margin-right:8px; border-radius:4px;")),
        span(hex, style = "vertical-align:middle; font-family: monospace;")
      )
    })
    
    tagList(
      checkboxGroupInput("fill_color_checkboxes", "Select one color to use for page gaps:",
                          choiceNames = choice_names,
                          choiceValues = as.list(values$color_palette),
                          selected = character(0),
                          inline = TRUE)
    )
  })
  
  # Enforce single selection: checking a new swatch unchecks any previous one.
  # Unchecking the only selected swatch leaves the selection empty (= white).
  observeEvent(input$fill_color_checkboxes, {
    if(length(input$fill_color_checkboxes) > 1) {
      newest <- tail(input$fill_color_checkboxes, 1)
      updateCheckboxGroupInput(session, "fill_color_checkboxes", selected = newest)
    }
  }, ignoreNULL = FALSE)
  
  observeEvent(input$create_img_pdf_btn, {
    req(input$img_files)
    
    if(is.null(values$img_pdf_directory) || length(values$img_pdf_directory) == 0 || values$img_pdf_directory == "") {
      showNotification("Please select an output directory first.", type = "warning", duration = 5)
      values$img_pdf_status_text <- "❌ Error: No output directory selected. Click 'Browse' to select one."
      return()
    }
    
    if(is.null(input$img_pdf_filename) || trimws(input$img_pdf_filename) == "") {
      showNotification("Please specify an output filename.", type = "warning", duration = 5)
      values$img_pdf_status_text <- "❌ Error: No output filename specified."
      return()
    }
    
    showNotification("Building PDF from images... This may take a while for large/many files.",
                     type = "message", duration = NULL, id = "processing_img_pdf")
    
    files_df <- img_files_sorted()
    n_files <- nrow(files_df)
    values$img_pdf_status_text <- paste0("Processing ", n_files, " image(s)...")
    
    tryCatch({
      # Determine target page dimensions in pixels, honoring chosen size + orientation
      dims_in <- STANDARD_PAGE_SIZES[[input$img_page_size]]
      page_w_in <- dims_in[1]
      page_h_in <- dims_in[2]
      
      if(input$img_orientation == "Landscape") {
        if(page_w_in < page_h_in) {
          tmp <- page_w_in; page_w_in <- page_h_in; page_h_in <- tmp
        }
      } else {
        if(page_h_in < page_w_in) {
          tmp <- page_w_in; page_w_in <- page_h_in; page_h_in <- tmp
        }
      }
      
      page_w_px <- round(page_w_in * IMG_TO_PDF_DPI)
      page_h_px <- round(page_h_in * IMG_TO_PDF_DPI)
      page_geometry <- paste0(page_w_px, "x", page_h_px)
      
      rotation_deg <- as.numeric(input$img_rotation)
      
      # Determine the fill color for letterbox gaps / transparency flattening:
      # the color the user checked from the sample-image palette, or white if none checked
      if(!is.null(input$fill_color_checkboxes) && length(input$fill_color_checkboxes) > 0) {
        fill_color <- input$fill_color_checkboxes[1]
      } else {
        fill_color <- "white"
      }
      
      # Build output path
      output_filename <- trimws(input$img_pdf_filename)
      if(!grepl("\\.pdf$", output_filename, ignore.case = TRUE)) {
        output_filename <- paste0(output_filename, ".pdf")
      }
      output_path <- file.path(values$img_pdf_directory, output_filename)
      
      if(!dir.exists(values$img_pdf_directory)) {
        dir.create(values$img_pdf_directory, recursive = TRUE)
      }
      
      if(file.exists(output_path)) {
        showNotification("Warning: Output file already exists and will be overwritten.",
                         type = "warning", duration = 3)
      }
      
      processed_images <- list()
      skipped_files <- character(0)
      
      withProgress(message = "Building PDF from images", value = 0, {
        for(i in 1:n_files) {
          file_name <- files_df$name[i]
          file_path <- files_df$datapath[i]
          
          incProgress(1 / n_files, detail = paste("Processing", file_name))
          
          img_result <- tryCatch({
            if(!file.exists(file_path)) {
              stop("File does not exist or cannot be accessed")
            }
            
            img <- magick::image_read(file_path)
            
            # Animated GIFs: use only the first frame
            if(length(img) > 1) {
              img <- img[1]
            }
            
            # Flatten any transparency (common in Windows PNG screenshots) onto
            # the chosen fill color BEFORE rotating/resizing, so nothing ends up
            # invisible or with black/checkerboard artifacts in the final PDF
            img <- magick::image_background(img, fill_color, flatten = TRUE)
            
            # Rotate the image if requested
            if(rotation_deg != 0) {
              img <- magick::image_rotate(img, rotation_deg)
            }
            
            # Cap resolution to the target print quality (shrink only, never
            # upscale) purely to keep file size/render time reasonable
            img <- magick::image_resize(img, paste0(page_geometry, ">"))
            
            info <- magick::image_info(img)
            if(is.null(info) || nrow(info) == 0 || info$width[1] <= 0 || info$height[1] <= 0) {
              stop("Image has invalid or zero dimensions after processing")
            }
            
            list(
              raster = grDevices::as.raster(img),
              aspect_ratio = info$width[1] / info$height[1]
            )
          }, error = function(e) {
            skipped_files <<- c(skipped_files, paste0(file_name, " (error: ", e$message, ")"))
            NULL
          })
          
          if(!is.null(img_result)) {
            processed_images[[length(processed_images) + 1]] <- img_result
          }
        }
      })
      
      if(length(processed_images) == 0) {
        stop("No images could be processed. All files were skipped due to errors.")
      }
      
      # Write the PDF using R's native pdf() graphics device (grDevices), NOT
      # ImageMagick's own PDF encoder - the latter depends on the system's
      # Ghostscript/delegate configuration and can silently emit blank pages.
      # Drawing each image as a raster via grid onto a pdf() device page is
      # reliable regardless of the host machine's ImageMagick setup.
      page_aspect_ratio <- page_w_in / page_h_in
      
      grDevices::pdf(file = output_path, width = page_w_in, height = page_h_in, onefile = TRUE)
      pdf_device_open <- TRUE
      tryCatch({
        for(item in processed_images) {
          grid::grid.newpage()
          # Fill the full page with the chosen fill color first (letterboxing around non-matching aspect ratios)
          grid::grid.rect(gp = grid::gpar(fill = fill_color, col = NA))
          
          img_ar <- item$aspect_ratio
          if(img_ar > page_aspect_ratio) {
            draw_width_npc <- 1
            draw_height_npc <- page_aspect_ratio / img_ar
          } else {
            draw_height_npc <- 1
            draw_width_npc <- img_ar / page_aspect_ratio
          }
          
          grid::grid.raster(item$raster,
                            x = 0.5, y = 0.5,
                            width = grid::unit(draw_width_npc, "npc"),
                            height = grid::unit(draw_height_npc, "npc"),
                            just = "center")
        }
      }, finally = {
        grDevices::dev.off()
        pdf_device_open <- FALSE
      })
      
      if(!file.exists(output_path) || file.size(output_path) == 0) {
        stop("PDF creation appeared to complete but output file was not created or is empty")
      }
      
      output_size <- round(file.size(output_path) / 1024 / 1024, 2)
      
      removeNotification("processing_img_pdf")
      
      status_msg <- paste0("✅ Successfully created a ", length(processed_images), "-page PDF from ",
                           length(processed_images), " of ", n_files, " image(s)!\n\n",
                           "Output: ", basename(output_path), " (", output_size, " MB)\n",
                           "Location: ", values$img_pdf_directory, "\n",
                           "Page Size: ", input$img_page_size, " (", input$img_orientation, ")\n",
                           "Image Rotation: ", rotation_deg, " degrees\n",
                           "Gap Fill Color: ", 
                           if(fill_color != "white") paste0(fill_color, " (from sample image palette)") else "White (default)")
      
      if(length(skipped_files) > 0) {
        status_msg <- paste0(status_msg, "\n\n⚠ Skipped files:\n",
                             paste0("- ", skipped_files, collapse = "\n"))
      }
      
      values$img_pdf_status_text <- status_msg
      
      showNotification(paste("PDF successfully created:", basename(output_path)),
                       type = "message", duration = 5)
      
    }, error = function(e) {
      removeNotification("processing_img_pdf")
      
      error_msg <- paste0("❌ Error creating PDF from images:\n", e$message)
      values$img_pdf_status_text <- error_msg
      
      showNotification(paste("Error creating PDF:", e$message), type = "error", duration = 10)
    })
  })
  
  output$img_pdf_status <- renderText({
    values$img_pdf_status_text
  })
}

# Run the application
shinyApp(ui = ui, server = server)