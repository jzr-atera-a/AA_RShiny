# Load required libraries
library(shiny)
library(shinydashboard)
library(shinyFiles)
library(pdftools)
library(qpdf)
library(fs)

# Configure Shiny options for large file uploads
options(shiny.maxRequestSize = -1)  # Remove file size limit completely

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
      menuItem("PDF Merger", tabName = "merger", icon = icon("puzzle-piece"))
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
  
  # Reactive values
  values <- reactiveValues(
    pdf_pages = NULL,
    pdf_name = NULL,
    split_plan = NULL,
    output_directory = NULL,
    merge_directory = NULL,
    merge_status_text = "Ready to merge PDFs. Select at least 2 files and output path, then click 'Merge PDFs'."
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
}

# Run the application
shinyApp(ui = ui, server = server)