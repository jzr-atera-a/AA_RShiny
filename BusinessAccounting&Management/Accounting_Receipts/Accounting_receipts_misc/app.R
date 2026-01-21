library(shiny)
library(shinydashboard)
library(httr)
library(jsonlite)
library(base64enc)
library(DT)
library(dplyr)
library(openxlsx)
library(shinyFiles)

# Optional packages for PDF to JPG conversion (install if needed):
# install.packages("pdftools")
# install.packages("magick")
# install.packages("shinyFiles")

# UI Definition
ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "Receipt Processor"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Settings", tabName = "settings", icon = icon("cog")),
      menuItem("PDF to JPG Converter", tabName = "converter", icon = icon("file-image")),
      menuItem("Convert to PDF", tabName = "topdf", icon = icon("file-pdf")),
      menuItem("Upload Receipts", tabName = "upload", icon = icon("upload")),
      menuItem("View Processed Data", tabName = "data", icon = icon("table")),
      menuItem("Categorize Receipts", tabName = "categorize", icon = icon("tags"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        /* Paleta de colores */
        :root {
          --deep-blue: #0a1128;
          --dark-blue: #1e3c72;
          --medium-blue: #2a5298;
          --bright-blue: #4a90e2;
          --light-blue: #7ec8e3;
          --purple-dark: #3d1f4f;
          --purple-medium: #5e2e6c;
          --purple-light: #764ba2;
        }
        
        .skin-blue .main-header .navbar {
          background: linear-gradient(90deg, #1e3c72 0%, #2a5298 50%, #4a90e2 100%) !important;
          border-bottom: 3px solid #7ec8e3;
        }
        
        .skin-blue .main-header .logo {
          background: linear-gradient(135deg, #0a1128 0%, #1e3c72 100%) !important;
          color: #ffffff !important;
          font-weight: 600;
          border-right: 2px solid #4a90e2;
        }
        
        .skin-blue .main-sidebar {
          background: linear-gradient(180deg, #0a1128 0%, #1e3c72 50%, #2a5298 100%) !important;
          box-shadow: 4px 0 15px rgba(10, 17, 40, 0.5);
        }
        
        .skin-blue .main-sidebar .sidebar .sidebar-menu .active a {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          color: #ffffff !important;
          font-weight: bold;
          border-left: 4px solid #7ec8e3;
          box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        }
        
        .skin-blue .main-sidebar .sidebar .sidebar-menu a {
          color: #e0e7ff !important;
          transition: all 0.3s ease;
        }
        
        .skin-blue .main-sidebar .sidebar .sidebar-menu a:hover {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
          color: #ffffff !important;
          border-left: 4px solid #7ec8e3;
          transform: translateX(5px);
        }
        
        .content-wrapper {
          background: linear-gradient(135deg, #0a1128 0%, #1a2744 100%) !important;
        }
        
        .box {
          background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%) !important;
          border: 2px solid #4a90e2 !important;
          border-radius: 12px !important;
          box-shadow: 0 8px 25px rgba(74, 144, 226, 0.3) !important;
          transition: all 0.3s ease;
        }
        
        .box:hover {
          box-shadow: 0 12px 35px rgba(74, 144, 226, 0.5) !important;
          transform: translateY(-2px);
        }
        
        .box.box-primary .box-header {
          color: #ffffff !important;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          border-radius: 10px 10px 0 0 !important;
          border-bottom: 2px solid #4a90e2 !important;
          padding: 15px;
          font-weight: 600;
        }
        
        .box.box-info .box-header {
          color: #ffffff !important;
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
          border-radius: 10px 10px 0 0 !important;
          border-bottom: 2px solid #7ec8e3 !important;
          padding: 15px;
          font-weight: 600;
        }
        
        .box.box-success .box-header {
          color: #ffffff !important;
          background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%) !important;
          border-radius: 10px 10px 0 0 !important;
          border-bottom: 2px solid #7ec8e3 !important;
          padding: 15px;
          font-weight: 600;
        }
        
        .box.box-warning .box-header {
          color: #ffffff !important;
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important;
          border-radius: 10px 10px 0 0 !important;
          border-bottom: 2px solid #7ec8e3 !important;
          padding: 15px;
          font-weight: 600;
        }
        
        .box-body {
          background: linear-gradient(135deg, #0f1f3f 0%, #1a2f5a 100%) !important;
          color: #e0e7ff !important;
          padding: 20px !important;
          border-radius: 0 0 10px 10px;
        }
        
        p { 
          color: #c7d2fe !important; 
          line-height: 1.7 !important; 
        }
        
        strong { 
          color: #7ec8e3 !important; 
          font-weight: 600;
        }
        
        h3, h4, h5, h6 {
          color: #ffffff !important;
        }
        
        .form-control {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          color: #ffffff !important;
          border: 2px solid #4a90e2 !important;
          border-radius: 8px;
        }
        
        .btn {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          color: #ffffff !important;
          border: none !important;
          border-radius: 8px;
          padding: 10px 20px;
          font-weight: bold;
          transition: all 0.3s ease;
          box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
        }
        
        .btn:hover {
          background: linear-gradient(135deg, #764ba2 0%, #667eea 100%) !important;
          transform: translateY(-2px);
          box-shadow: 0 6px 20px rgba(118, 75, 162, 0.4);
        }
        
        .btn-success {
          background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%) !important;
        }
        
        .btn-info {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
        }
        
        .btn-warning {
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important;
        }
        
        .btn-primary {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
        }
        
        .info-box {
          background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%) !important;
          color: #ffffff !important;
          border: 2px solid #4a90e2;
          border-radius: 8px;
          box-shadow: 0 4px 15px rgba(74, 144, 226, 0.3);
        }
        
        .info-box-icon {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
        }
        
        .info-box-text {
          color: #e0e7ff !important;
        }
        
        .info-box-number {
          color: #7ec8e3 !important;
          font-weight: bold;
        }
        
        table.dataTable {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          color: #e0e7ff !important;
        }
        
        table.dataTable thead th {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          color: #ffffff !important;
          border-bottom: 2px solid #4a90e2 !important;
        }
        
        table.dataTable tbody tr {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          color: #e0e7ff !important;
        }
        
        table.dataTable tbody tr:hover {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
        }
        
        ::-webkit-scrollbar {
          width: 12px;
        }
        
        ::-webkit-scrollbar-track {
          background: #0a1128;
        }
        
        ::-webkit-scrollbar-thumb {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%);
          border-radius: 6px;
        }
        
        .alert-success {
          background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%) !important;
          border-color: #7ec8e3 !important;
          color: #ffffff !important;
          padding: 15px;
          border-radius: 8px;
          margin: 10px 0;
        }
        
        .alert-danger {
          background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important;
          border-color: #e74c3c !important;
          color: #ffffff !important;
          padding: 15px;
          border-radius: 8px;
          margin: 10px 0;
        }
        
        .alert-info {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
          border-color: #7ec8e3 !important;
          color: #ffffff !important;
          padding: 15px;
          border-radius: 8px;
          margin: 10px 0;
        }
        
        .category-totals {
          background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
          border: 2px solid #4a90e2;
          border-radius: 8px;
          padding: 20px;
          margin: 20px 0;
        }
        
        .category-total-item {
          display: inline-block;
          margin: 10px 15px;
          padding: 15px 25px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          border-radius: 8px;
          min-width: 150px;
          text-align: center;
        }
        
        .category-total-label {
          color: #e0e7ff;
          font-size: 14px;
          font-weight: 600;
        }
        
        .category-total-amount {
          color: #7ec8e3;
          font-size: 24px;
          font-weight: bold;
          margin-top: 5px;
        }
      "))
    ),
    
    tabItems(
      # Settings Tab (First)
      tabItem(
        tabName = "settings",
        fluidRow(
          box(
            title = "API Configuration",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            passwordInput(
              "api_key",
              "OpenAI API Key:",
              placeholder = "Enter your API key (starts with sk-proj-... or sk-...)"
            ),
            p(strong("Get your API key from:"), " https://platform.openai.com/api-keys"),
            hr(),
            textInput(
              "receipts_folder",
              "Receipts Storage Folder:",
              value = "receipts"
            ),
            textInput(
              "excel_filename",
              "Excel Output Filename:",
              value = "receipt_data.xlsx"
            ),
            hr(),
            actionButton("save_settings", "Save Settings", class = "btn-success", icon = icon("save")),
            actionButton("test_api", "Test API Connection", class = "btn-info", icon = icon("flask")),
            hr(),
            verbatimTextOutput("settings_status"),
            hr(),
            uiOutput("test_result")
          )
        )
      ),
      
      # PDF to JPG Converter Tab
      tabItem(
        tabName = "converter",
        fluidRow(
          box(
            title = "PDF to JPG Converter",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            p(strong("Instructions:"), "Upload PDF files to convert them to JPG images. Each page will be saved as a separate JPG file."),
            hr(),
            fileInput(
              "pdf_files",
              "Choose PDF Files:",
              multiple = TRUE,
              accept = c(".pdf", "application/pdf"),
              placeholder = "Select one or more PDF files"
            ),
            numericInput(
              "jpg_dpi",
              "Image Quality (DPI):",
              value = 300,
              min = 72,
              max = 600,
              step = 50
            ),
            p(class = "text-muted", "Higher DPI = better quality but larger file size. Recommended: 300 DPI"),
            hr(),
            textInput(
              "converter_output_path",
              "Output Folder Path:",
              value = file.path(getwd(), "converted_images"),
              placeholder = "Enter full path where JPG files will be saved"
            ),
            p(class = "text-muted", strong("Example paths:")),
            p(class = "text-muted", "Windows: C:/Users/YourName/Documents/converted_images"),
            p(class = "text-muted", "Mac/Linux: /home/username/Documents/converted_images"),
            actionButton("browse_converter_folder", "Show Path Info", 
                         class = "btn-info", icon = icon("info-circle")),
            hr(),
            actionButton("convert_pdf", "Convert PDFs to JPG", 
                         class = "btn-success", icon = icon("magic")),
            hr(),
            uiOutput("conversion_status")
          )
        ),
        fluidRow(
          box(
            title = "Conversion Results",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            p("This table shows the results of PDF to JPG conversions."),
            DT::dataTableOutput("conversion_results_table")
          )
        )
      ),
      
      # Convert to PDF Tab
      tabItem(
        tabName = "topdf",
        fluidRow(
          box(
            title = "Convert Images to PDF",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            p(strong("Instructions:"), "Convert JPG, JPEG, PNG, and other image files to PDF format. Browse and select individual files or an entire folder."),
            hr(),
            radioButtons(
              "pdf_input_type",
              "Select Input Type:",
              choices = c("Individual Files" = "files", "Entire Folder" = "folder"),
              selected = "files"
            ),
            conditionalPanel(
              condition = "input.pdf_input_type == 'files'",
              fileInput(
                "image_files_to_pdf",
                "Choose Image Files:",
                multiple = TRUE,
                accept = c(".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".gif", "image/*"),
                placeholder = "Select one or more image files"
              )
            ),
            conditionalPanel(
              condition = "input.pdf_input_type == 'folder'",
              shinyDirButton(
                "image_folder_browser",
                "Browse for Input Folder",
                "Select folder containing images",
                class = "btn-primary",
                icon = icon("folder-open")
              ),
              hr(),
              verbatimTextOutput("selected_input_folder"),
              verbatimTextOutput("input_folder_status")
            ),
            hr(),
            selectInput(
              "pdf_page_size",
              "PDF Page Size:",
              choices = c("A4" = "A4", "Letter" = "letter"),
              selected = "A4"
            ),
            p(class = "text-muted", "A4: 210 x 297 mm (International) | Letter: 8.5 x 11 inches (US)"),
            hr(),
            shinyDirButton(
              "pdf_output_browser",
              "Browse for Output Folder",
              "Select folder to save PDF files",
              class = "btn-primary",
              icon = icon("folder-open")
            ),
            hr(),
            verbatimTextOutput("selected_output_folder"),
            verbatimTextOutput("output_folder_status"),
            hr(),
            actionButton("convert_to_pdf", "Convert to PDF", 
                         class = "btn-success", icon = icon("file-pdf")),
            hr(),
            uiOutput("pdf_conversion_status")
          )
        ),
        fluidRow(
          box(
            title = "Conversion Results",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            p("This table shows the results of image to PDF conversions. Original image files are NOT deleted."),
            DT::dataTableOutput("pdf_conversion_results_table")
          )
        )
      ),
      
      # Upload Tab
      tabItem(
        tabName = "upload",
        fluidRow(
          box(
            title = "Upload Receipt Images",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            p(strong("Instructions:"), "Upload up to 5 receipt images in JPG or JPEG format. Files will be saved with descriptive names based on the receipt content."),
            hr(),
            p(strong("Filename Format:"), "ProviderName_Description_YYYYMMDD_Amount.jpg"),
            p(strong("Examples:"), "Trainline_London_to_Manchester_20251115_14.92.jpg or Booking_com_Paris_20251110_85.50.jpg"),
            hr(),
            fileInput(
              "receipt_files",
              "Choose Receipt Files (JPG or JPEG only - PDFs not supported by OpenAI Vision API)",
              multiple = TRUE,
              accept = c(".jpg", ".jpeg", "image/jpeg"),
              placeholder = "Select up to 5 files"
            ),
            actionButton("process_btn", "Process Receipts", 
                         class = "btn-primary", icon = icon("play-circle")),
            hr(),
            uiOutput("upload_status")
          )
        ),
        fluidRow(
          box(
            title = "Processing Results",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            p("The results below show the extracted information from the receipts you just processed. Amounts are stored as numeric values (no currency symbols)."),
            DT::dataTableOutput("results_table")
          )
        )
      ),
      
      # Data View Tab
      tabItem(
        tabName = "data",
        fluidRow(
          box(
            title = "All Processed Receipts",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            p("This table shows all receipts that have been processed and saved to the Excel file. Amount column contains numeric values only."),
            hr(),
            actionButton("refresh_data", "Refresh Data", icon = icon("refresh"), class = "btn-info"),
            downloadButton("download_excel", "Download Excel", class = "btn-success"),
            hr(),
            DT::dataTableOutput("all_data_table")
          )
        )
      ),
      
      # Categorize Tab
      tabItem(
        tabName = "categorize",
        fluidRow(
          box(
            title = "Categorize Receipts",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            p(strong("Instructions:"), "Edit the category columns to categorize receipts. Use 0 or 1 values (0 = unchecked, 1 = checked). Only ONE category should be set to 1 per receipt."),
            hr(),
            p(strong("Categories:"), "Labour, Overheads, Materials, Capital Usage (Capital_Usage), T&S (TS), Contractor"),
            hr(),
            p(strong("How it works:"), "When you set any category to 1, all other categories in that row automatically become 0 (radio button behavior). Category totals update automatically below."),
            hr(),
            textInput(
              "category_base_path",
              "Category Folders Base Path:",
              value = file.path(getwd(), "categorized_receipts"),
              placeholder = "Enter path where category folders will be created"
            ),
            p(class = "text-muted", strong("Folders will be created:")),
            p(class = "text-muted", "Labour/, Overheads/, Materials/, Capital_Usage/, TS/, Contractor/"),
            p(class = "text-muted", strong("Example paths:")),
            p(class = "text-muted", "Windows: C:/Users/YourName/Documents/categorized_receipts"),
            p(class = "text-muted", "Mac/Linux: /home/username/Documents/categorized_receipts"),
            actionButton("browse_category_folder", "Show Path Info", 
                         class = "btn-info", icon = icon("info-circle")),
            hr(),
            actionButton("save_categories", "Save Categories to Excel", 
                         class = "btn-success", icon = icon("save")),
            actionButton("copy_files_to_categories", "Copy Files to Category Folders", 
                         class = "btn-warning", icon = icon("copy")),
            actionButton("refresh_categorize", "Refresh Data", 
                         class = "btn-info", icon = icon("refresh")),
            hr(),
            uiOutput("category_totals_ui"),
            hr(),
            p(strong("Edit the table below:"), "Click on any cell in the category columns (columns 2-7) to edit. Other columns are read-only."),
            DT::dataTableOutput("categorize_table")
          )
        )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Reactive values to store data
  rv <- reactiveValues(
    api_key = NULL,
    receipts_folder = "receipts",
    excel_filename = "receipt_data.xlsx",
    current_results = NULL,
    all_data = NULL,
    categorize_data = NULL,
    conversion_results = NULL,
    pdf_conversion_results = NULL,
    category_totals = NULL
  )
  
  # Initialize folder browsers (for Windows and all platforms)
  # For Windows: Show all drives (C:, D:, etc.) and Home
  # For Mac/Linux: Show root and Home
  if (.Platform$OS.type == "windows") {
    volumes <- c(
      "C:" = "C:/",
      "D:" = "D:/",
      "E:" = "E:/",
      Home = fs::path_home(),
      getVolumes()()
    )
  } else {
    volumes <- c(
      Root = "/",
      Home = fs::path_home(),
      getVolumes()()
    )
  }
  
  # Input folder browser
  shinyDirChoose(input, "image_folder_browser", roots = volumes, session = session, restrictions = system.file(package = "base"))
  
  # Output folder browser
  shinyDirChoose(input, "pdf_output_browser", roots = volumes, session = session, restrictions = system.file(package = "base"))
  
  # Reactive value to store selected folders
  selected_input_folder <- reactiveVal(NULL)
  selected_output_folder <- reactiveVal(NULL)
  
  # Handle input folder selection
  observeEvent(input$image_folder_browser, {
    if (!is.integer(input$image_folder_browser)) {
      folder_path <- parseDirPath(volumes, input$image_folder_browser)
      
      if (length(folder_path) > 0) {
        # Convert to proper path string
        folder_path <- as.character(folder_path)
        
        if (dir.exists(folder_path)) {
          selected_input_folder(folder_path)
          
          # Display selected folder
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
        # Convert to proper path string
        folder_path <- as.character(folder_path)
        
        selected_output_folder(folder_path)
        
        # Create folder if it doesn't exist
        if (!dir.exists(folder_path)) {
          dir.create(folder_path, recursive = TRUE)
        }
        
        # Display selected folder
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
  
  # Initialize folders and files on startup
  observe({
    # Create receipts folder if it doesn't exist
    if (!dir.exists(rv$receipts_folder)) {
      dir.create(rv$receipts_folder, recursive = TRUE)
    }
    
    # Create Excel file with headers if it doesn't exist
    if (!file.exists(rv$excel_filename)) {
      empty_df <- data.frame(
        receipt_id = character(),
        filename = character(),
        provider = character(),
        amount = numeric(),
        date = character(),
        description = character(),
        processed_timestamp = character(),
        Labour = integer(),
        Overheads = integer(),
        Materials = integer(),
        Capital_Usage = integer(),
        TS = integer(),
        Contractor = integer(),
        stringsAsFactors = FALSE
      )
      write.xlsx(empty_df, rv$excel_filename)
    }
  })
  
  # Function to create safe filename
  create_safe_filename <- function(text, max_length = NULL) {
    # Remove or replace unsafe characters
    safe_text <- gsub("[^a-zA-Z0-9 ]", "", text)
    safe_text <- gsub("\\s+", "_", safe_text)
    safe_text <- trimws(safe_text)
    
    # Limit length if specified
    if (!is.null(max_length) && nchar(safe_text) > max_length) {
      safe_text <- substr(safe_text, 1, max_length)
    }
    
    return(safe_text)
  }
  
  # Function to create renamed filename
  create_renamed_filename <- function(provider, description, date, amount, original_ext) {
    # Clean provider name
    provider_clean <- create_safe_filename(provider, max_length = 50)
    if (provider_clean == "" || provider_clean == "N_A") provider_clean <- "Unknown"
    
    # Get first 40 characters of description for trains/accommodation, 20 for others
    desc_clean <- create_safe_filename(description, max_length = 40)
    if (desc_clean == "" || desc_clean == "N_A") desc_clean <- "NoDescription"
    
    # Format date as YYYYMMDD
    date_formatted <- gsub("-", "", date)
    if (nchar(date_formatted) != 8 || date_formatted == "N_A") {
      date_formatted <- format(Sys.Date(), "%Y%m%d")
    }
    
    # Format amount
    amount_formatted <- sprintf("%.2f", amount)
    
    # Combine: ProviderName_Description_YYYYMMDD_Amount.ext
    new_filename <- paste0(
      provider_clean, "_",
      desc_clean, "_",
      date_formatted, "_",
      amount_formatted,
      original_ext
    )
    
    return(new_filename)
  }
  
  # Save settings
  observeEvent(input$save_settings, {
    # Trim whitespace from API key
    rv$api_key <- trimws(input$api_key)
    rv$receipts_folder <- input$receipts_folder
    rv$excel_filename <- input$excel_filename
    
    # Validate API key format for OpenAI
    api_key_valid <- nchar(rv$api_key) > 0 && grepl("^sk-", rv$api_key)
    
    # Create folder if it doesn't exist
    if (!dir.exists(rv$receipts_folder)) {
      dir.create(rv$receipts_folder, recursive = TRUE)
    }
    
    # Display status
    output$settings_status <- renderText({
      paste0("Settings saved successfully!\n",
             "API Key: ", ifelse(nchar(rv$api_key) > 0, 
                                 ifelse(api_key_valid, "Set ✓", "Set (Warning: should start with 'sk-')"), 
                                 "Not Set ✗"), "\n",
             "Receipts Folder: ", rv$receipts_folder, "\n",
             "Excel Filename: ", rv$excel_filename, "\n",
             "Last Updated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
    })
    
    # Show notification
    if (!api_key_valid && nchar(rv$api_key) > 0) {
      showNotification("Warning: API key should start with 'sk-'", type = "warning", duration = 5)
    } else if (api_key_valid) {
      showNotification("Settings saved successfully! You can now test the API connection or process receipts.", 
                       type = "message", duration = 3)
    }
  })
  
  # Test API Connection
  observeEvent(input$test_api, {
    if (is.null(rv$api_key) || nchar(rv$api_key) == 0) {
      output$test_result <- renderUI({
        tags$div(
          class = "alert alert-danger",
          tags$strong("Error: "),
          "Please enter and save your API key first."
        )
      })
      return()
    }
    
    # Show testing message
    output$test_result <- renderUI({
      tags$div(
        class = "alert alert-info",
        tags$strong("Testing... "),
        "Connecting to OpenAI API..."
      )
    })
    
    # Test API with a simple request
    tryCatch({
      response <- POST(
        url = "https://api.openai.com/v1/chat/completions",
        add_headers(
          `Authorization` = paste("Bearer", rv$api_key),
          `Content-Type` = "application/json"
        ),
        body = list(
          model = "gpt-4o",
          messages = list(
            list(
              role = "user",
              content = "Say 'API test successful' if you receive this message."
            )
          ),
          max_tokens = 10
        ),
        encode = "json",
        timeout(30)
      )
      
      if (status_code(response) == 200) {
        output$test_result <- renderUI({
          tags$div(
            class = "alert alert-success",
            tags$strong("✓ Success! "),
            "API connection is working correctly. You can now process receipts.",
            tags$br(), tags$br(),
            tags$small(paste("Response received at:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
          )
        })
        showNotification("API test successful!", type = "message", duration = 3)
      } else if (status_code(response) == 401) {
        output$test_result <- renderUI({
          tags$div(
            class = "alert alert-danger",
            tags$strong("✗ Authentication Failed (401): "),
            "Your API key is invalid or has expired. Please check your key at https://platform.openai.com/api-keys"
          )
        })
      } else if (status_code(response) == 429) {
        output$test_result <- renderUI({
          tags$div(
            class = "alert alert-danger",
            tags$strong("✗ Rate Limit Exceeded (429): "),
            "Too many requests. Please wait a moment and try again."
          )
        })
      } else {
        output$test_result <- renderUI({
          tags$div(
            class = "alert alert-danger",
            tags$strong("✗ Error: "),
            paste("API returned status code:", status_code(response))
          )
        })
      }
    }, error = function(e) {
      output$test_result <- renderUI({
        tags$div(
          class = "alert alert-danger",
          tags$strong("✗ Connection Error: "),
          paste("Could not connect to OpenAI API:", e$message)
        )
      })
    })
  })
  
  # PDF Converter - Show path info
  observeEvent(input$browse_converter_folder, {
    showNotification(
      "Enter the full folder path in the text box above. The folder will be created automatically if it doesn't exist.",
      type = "message",
      duration = 8
    )
  })
  
  # PDF Converter - Convert PDFs
  observeEvent(input$convert_pdf, {
    req(input$pdf_files)
    
    # Check if pdftools package is available
    if (!requireNamespace("pdftools", quietly = TRUE)) {
      showModal(modalDialog(
        title = "Package Required",
        HTML("The 'pdftools' package is required for PDF conversion.<br><br>
             Please install it by running:<br>
             <code>install.packages('pdftools')</code>"),
        easyClose = TRUE,
        footer = modalButton("OK")
      ))
      return()
    }
    
    # Check if magick package is available
    if (!requireNamespace("magick", quietly = TRUE)) {
      showModal(modalDialog(
        title = "Package Required",
        HTML("The 'magick' package is required for image conversion.<br><br>
             Please install it by running:<br>
             <code>install.packages('magick')</code>"),
        easyClose = TRUE,
        footer = modalButton("OK")
      ))
      return()
    }
    
    # Get output folder
    if (input$pdf_input_type == "files") {
      # For individual files, output folder must be selected
      req(selected_output_folder())
      output_folder <- as.character(selected_output_folder())
      
      if (length(output_folder) == 0 || is.null(output_folder)) {
        showModal(modalDialog(
          title = "Output Folder Required",
          "Please click 'Browse for Output Folder' button to select where PDF files will be saved.",
          easyClose = TRUE,
          footer = modalButton("OK")
        ))
        return()
      }
    } else {
      # For folder input, output folder must also be selected
      req(selected_output_folder())
      output_folder <- as.character(selected_output_folder())
      
      if (length(output_folder) == 0 || is.null(output_folder)) {
        showModal(modalDialog(
          title = "Output Folder Required",
          "Please click 'Browse for Output Folder' button to select where PDF files will be saved.",
          easyClose = TRUE,
          footer = modalButton("OK")
        ))
        return()
      }
    }
    
    # Create folder if it doesn't exist
    if (!dir.exists(output_folder)) {
      dir.create(output_folder, recursive = TRUE)
      showNotification(paste("Created folder:", output_folder), type = "message", duration = 3)
    }
    
    # Show progress
    withProgress(message = 'Converting PDFs...', value = 0, {
      
      results_list <- list()
      total_images <- 0
      
      for (i in 1:nrow(input$pdf_files)) {
        file_info <- input$pdf_files[i, ]
        incProgress(1/nrow(input$pdf_files), 
                    detail = paste("Converting", file_info$name))
        
        tryCatch({
          # Get PDF info
          pdf_info <- pdftools::pdf_info(file_info$datapath)
          num_pages <- pdf_info$pages
          
          # Get base filename without extension
          base_name <- tools::file_path_sans_ext(file_info$name)
          
          # Convert each page
          page_files <- c()
          for (page_num in 1:num_pages) {
            # Create output filename
            if (num_pages > 1) {
              output_filename <- paste0(base_name, "_page_", 
                                        sprintf("%03d", page_num), ".jpg")
            } else {
              output_filename <- paste0(base_name, ".jpg")
            }
            
            output_path <- file.path(output_folder, output_filename)
            
            # Convert PDF page to image using magick
            img <- magick::image_read_pdf(file_info$datapath, 
                                          pages = page_num, 
                                          density = input$jpg_dpi)
            magick::image_write(img, output_path, format = "jpeg", quality = 95)
            
            page_files <- c(page_files, output_filename)
            total_images <- total_images + 1
          }
          
          # Add to results
          results_list[[i]] <- data.frame(
            pdf_file = file_info$name,
            pages = num_pages,
            output_files = paste(page_files, collapse = ", "),
            status = "Success",
            stringsAsFactors = FALSE
          )
          
        }, error = function(e) {
          results_list[[i]] <- data.frame(
            pdf_file = file_info$name,
            pages = NA,
            output_files = "",
            status = paste("Error:", e$message),
            stringsAsFactors = FALSE
          )
        })
      }
      
      # Combine results
      results_df <- do.call(rbind, results_list)
      rv$conversion_results <- results_df
    })
    
    # Show success message
    success_count <- sum(rv$conversion_results$status == "Success")
    error_count <- nrow(rv$conversion_results) - success_count
    
    output$conversion_status <- renderUI({
      if (error_count > 0) {
        tags$div(
          class = "alert alert-success",
          tags$strong("Completed! "),
          sprintf("Successfully converted %d PDF(s). %d error(s) occurred.", 
                  success_count, error_count),
          tags$br(),
          tags$small(paste("Files saved to:", output_folder))
        )
      } else {
        tags$div(
          class = "alert alert-success",
          tags$strong("✓ Success! "),
          sprintf("Successfully converted all %d PDF(s) to JPG images.", 
                  nrow(rv$conversion_results)),
          tags$br(),
          tags$small(paste("Files saved to:", output_folder))
        )
      }
    })
  })
  
  # Display conversion results
  output$conversion_results_table <- DT::renderDataTable({
    req(rv$conversion_results)
    DT::datatable(
      rv$conversion_results,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 'frtip'
      ),
      rownames = FALSE
    )
  })
  
  # Convert to PDF - Convert images to PDF
  # Convert to PDF - Convert images to PDF
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
      # Individual files selected
      req(input$image_files_to_pdf)
      files_to_convert <- input$image_files_to_pdf
    } else {
      # Folder selected via browser
      folder_val <- selected_input_folder()
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
      
      # Create a data frame similar to fileInput structure
      files_to_convert <- data.frame(
        name = basename(image_files),
        datapath = image_files,
        stringsAsFactors = FALSE
      )
    }
    
    # Get output folder - MUST be selected for both modes
    output_val <- selected_output_folder()
    if (is.null(output_val) || length(output_val) == 0) {
      showNotification("Please select output folder first", type = "error", duration = 5)
      return()
    }
    
    output_folder <- as.character(output_val)
    
    # Create folder if it doesn't exist
    if (!dir.exists(output_folder)) {
      dir.create(output_folder, recursive = TRUE)
    }
    
    # Get page size
    page_size <- input$pdf_page_size
    
    # Set page dimensions based on selection
    if (page_size == "A4") {
      page_width <- 210  # mm
      page_height <- 297  # mm
    } else {  # Letter
      page_width <- 215.9  # mm (8.5 inches)
      page_height <- 279.4  # mm (11 inches)
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
          
          # Create output filename (same name but .pdf extension)
          base_name <- tools::file_path_sans_ext(file_info$name)
          output_filename <- paste0(base_name, ".pdf")
          output_path <- file.path(output_folder, output_filename)
          
          # Convert to PDF with 300 DPI
          # Use density parameter in image_write for 300 DPI
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
  
  # Function to encode file to base64
  encode_file <- function(file_path) {
    file_content <- readBin(file_path, "raw", file.info(file_path)$size)
    base64encode(file_content)
  }
  
  # Function to determine media type
  get_media_type <- function(filename) {
    ext <- tolower(tools::file_ext(filename))
    if (ext %in% c("jpg", "jpeg")) {
      return("image/jpeg")
    } else if (ext == "pdf") {
      return("application/pdf")
    }
    return("image/jpeg")
  }
  
  # Function to call OpenAI API for receipt processing
  call_openai_api <- function(file_path, filename) {
    if (is.null(rv$api_key) || nchar(rv$api_key) == 0) {
      return(list(error = "API key not set"))
    }
    
    # Encode file to base64
    base64_data <- encode_file(file_path)
    media_type <- get_media_type(filename)
    
    # OpenAI only supports images in vision API, not PDFs
    if (media_type == "application/pdf") {
      return(list(error = "PDF files are not supported with OpenAI Vision API. Please use JPG/JPEG images only."))
    }
    
    # Prepare API request for OpenAI
    api_url <- "https://api.openai.com/v1/chat/completions"
    
    body <- list(
      model = "gpt-4o",
      messages = list(
        list(
          role = "user",
          content = list(
            list(
              type = "image_url",
              image_url = list(
                url = paste0("data:", media_type, ";base64,", base64_data)
              )
            ),
            list(
              type = "text",
              text = paste0(
                "Please analyze this purchase receipt and extract the following information:\n\n",
                "1. Provider/Seller name\n",
                "2. Final amount paid - IMPORTANT: Return ONLY the numeric value without any currency symbols (£, $, etc.). Just the number like 18.34\n",
                "3. Date of payment (in YYYY-MM-DD format if possible)\n",
                "4. Description of items or services purchased (brief summary)\n\n",
                "Respond ONLY with a valid JSON object in this exact format:\n",
                "{\n",
                '  "provider": "Name of provider/seller",\n',
                '  "amount": 18.34,\n',
                '  "date": "2025-11-13",\n',
                '  "description": "Brief description of items/services"\n',
                "}\n\n",
                "CRITICAL: The amount field must be a NUMBER (like 18.34), NOT a string with currency symbol.\n",
                "DO NOT include any text outside the JSON object. ",
                "DO NOT use markdown code blocks or backticks. ",
                "Return ONLY the JSON object."
              )
            )
          )
        )
      ),
      max_tokens = 500
    )
    
    # Make API request
    response <- tryCatch({
      POST(
        url = api_url,
        add_headers(
          `Authorization` = paste("Bearer", rv$api_key),
          `Content-Type` = "application/json"
        ),
        body = body,
        encode = "json",
        timeout(60)
      )
    }, error = function(e) {
      return(list(error = paste("API request failed:", e$message)))
    })
    
    if ("error" %in% names(response)) {
      return(response)
    }
    
    # Parse response
    if (status_code(response) == 200) {
      content <- content(response, "parsed")
      if (!is.null(content$choices) && length(content$choices) > 0) {
        response_text <- content$choices[[1]]$message$content
        
        # Clean up response text (remove markdown formatting if present)
        response_text <- gsub("```json\\s*", "", response_text)
        response_text <- gsub("```\\s*", "", response_text)
        response_text <- trimws(response_text)
        
        # Parse JSON
        tryCatch({
          parsed_data <- fromJSON(response_text)
          return(parsed_data)
        }, error = function(e) {
          return(list(error = paste("Failed to parse JSON response:", e$message, 
                                    "\nRaw response:", substr(response_text, 1, 200))))
        })
      } else {
        return(list(error = "API returned empty response"))
      }
    } else if (status_code(response) == 401) {
      return(list(error = "Authentication failed (401). Your API key is invalid. Check Settings tab."))
    } else if (status_code(response) == 429) {
      return(list(error = "Rate limit exceeded (429). Please wait a moment and try again."))
    } else if (status_code(response) == 400) {
      error_content <- tryCatch(content(response, "text", encoding = "UTF-8"), 
                                error = function(e) "Unknown error")
      return(list(error = paste("Bad request (400):", error_content)))
    } else {
      return(list(error = paste("API error: Status code", status_code(response))))
    }
  }
  
  # Process receipts
  observeEvent(input$process_btn, {
    req(input$receipt_files)
    
    # Check API key
    if (is.null(rv$api_key) || nchar(rv$api_key) == 0) {
      showModal(modalDialog(
        title = "API Key Required",
        "Please set your OpenAI API key in the Settings tab first.",
        easyClose = TRUE,
        footer = modalButton("OK")
      ))
      return()
    }
    
    # Check number of files
    if (nrow(input$receipt_files) > 5) {
      showModal(modalDialog(
        title = "Too Many Files",
        "Please upload a maximum of 5 files at a time.",
        easyClose = TRUE,
        footer = modalButton("OK")
      ))
      return()
    }
    
    # Show progress bar
    withProgress(message = 'Processing receipts...', value = 0, {
      
      results_list <- list()
      
      for (i in 1:nrow(input$receipt_files)) {
        file_info <- input$receipt_files[i, ]
        incProgress(1/nrow(input$receipt_files), 
                    detail = paste("Processing", file_info$name))
        
        # Generate unique ID for this receipt (temporary)
        receipt_id <- paste0("RCP_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_", 
                             sprintf("%03d", i))
        
        # Save with temporary filename first
        temp_filename <- paste0(receipt_id, "_", file_info$name)
        temp_filepath <- file.path(rv$receipts_folder, temp_filename)
        file.copy(file_info$datapath, temp_filepath)
        
        # Call OpenAI API to process the receipt
        result <- call_openai_api(file_info$datapath, file_info$name)
        
        # Extract and clean amount to ensure it's numeric
        amount_numeric <- if ("error" %in% names(result)) {
          0
        } else {
          # If amount is a string, extract numbers
          amt <- result$amount
          if (is.character(amt)) {
            amt_cleaned <- gsub("[^0-9.]", "", amt)
            as.numeric(amt_cleaned)
          } else {
            as.numeric(amt)
          }
        }
        
        # Create data frame with results
        if ("error" %in% names(result)) {
          # Error occurred - keep temp filename
          results_list[[i]] <- data.frame(
            receipt_id = receipt_id,
            filename = temp_filename,
            provider = "ERROR",
            amount = 0,
            date = "ERROR",
            description = result$error,
            processed_timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
            Labour = 0L,
            Overheads = 0L,
            Materials = 0L,
            Capital_Usage = 0L,
            TS = 0L,
            Contractor = 0L,
            stringsAsFactors = FALSE
          )
        } else {
          # Success - create descriptive filename
          original_ext <- paste0(".", tools::file_ext(file_info$name))
          
          # Smart description extraction based on provider/type
          smart_description <- result$description
          provider_lower <- tolower(result$provider)
          description_lower <- tolower(result$description)
          
          # Check if it's train-related
          if (grepl("train|rail|railway|trainline", provider_lower) || 
              grepl("train|rail|railway", description_lower)) {
            # Ask OpenAI to extract just origin and destination
            train_prompt_body <- list(
              model = "gpt-4o",
              messages = list(
                list(
                  role = "user",
                  content = paste0(
                    "From this train receipt description: '", result$description, 
                    "'\n\nExtract ONLY the origin station and destination station.\n",
                    "Format: OriginStation to DestinationStation\n",
                    "Example: 'London Euston to Manchester Piccadilly'\n",
                    "Keep station names clear and concise. Maximum 40 characters total.\n",
                    "Return ONLY the formatted route, nothing else."
                  )
                )
              ),
              max_tokens = 50
            )
            
            train_response <- tryCatch({
              POST(
                url = "https://api.openai.com/v1/chat/completions",
                add_headers(
                  `Authorization` = paste("Bearer", rv$api_key),
                  `Content-Type` = "application/json"
                ),
                body = train_prompt_body,
                encode = "json",
                timeout(30)
              )
            }, error = function(e) NULL)
            
            if (!is.null(train_response) && status_code(train_response) == 200) {
              train_content <- content(train_response, "parsed")
              if (!is.null(train_content$choices) && length(train_content$choices) > 0) {
                extracted_route <- trimws(train_content$choices[[1]]$message$content)
                if (nchar(extracted_route) > 0 && nchar(extracted_route) <= 60) {
                  smart_description <- extracted_route
                }
              }
            }
          }
          
          # Check if it's accommodation-related
          if (grepl("booking\\.com|airbnb|hotel|hostel|accommodation", provider_lower) || 
              grepl("hotel|accommodation|stay|night", description_lower)) {
            # Try to extract city/location from description
            city_match <- gsub(".*?\\b(in|at)\\s+([A-Za-z\\s]+).*", "\\2", result$description, ignore.case = TRUE)
            if (city_match != result$description && nchar(city_match) > 0 && nchar(city_match) < 30) {
              smart_description <- city_match
            }
          }
          
          # Create descriptive filename
          descriptive_filename <- create_renamed_filename(
            result$provider,
            smart_description,
            result$date,
            amount_numeric,
            original_ext
          )
          
          # Rename the file in receipts folder
          descriptive_filepath <- file.path(rv$receipts_folder, descriptive_filename)
          file.rename(temp_filepath, descriptive_filepath)
          
          # Store results with descriptive filename
          results_list[[i]] <- data.frame(
            receipt_id = receipt_id,
            filename = descriptive_filename,
            provider = ifelse(is.null(result$provider), "N/A", result$provider),
            amount = amount_numeric,
            date = ifelse(is.null(result$date), "N/A", result$date),
            description = ifelse(is.null(result$description), "N/A", result$description),
            processed_timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
            Labour = 0L,
            Overheads = 0L,
            Materials = 0L,
            Capital_Usage = 0L,
            TS = 0L,
            Contractor = 0L,
            stringsAsFactors = FALSE
          )
        }
      }
      
      # Combine all results into one data frame
      results_df <- do.call(rbind, results_list)
      rv$current_results <- results_df
      
      # Append to Excel file
      if (file.exists(rv$excel_filename)) {
        # Read existing data
        existing_data <- read.xlsx(rv$excel_filename)
        
        # Add category columns if they don't exist in existing data
        category_cols <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
        for (col in category_cols) {
          if (!col %in% names(existing_data)) {
            existing_data[[col]] <- 0L
          }
        }
        
        # Ensure amount column is numeric in existing data
        if ("amount" %in% names(existing_data)) {
          existing_data$amount <- as.numeric(existing_data$amount)
        }
        
        # Combine old and new data
        combined_data <- rbind(existing_data, results_df)
        write.xlsx(combined_data, rv$excel_filename)
      } else {
        # Create new Excel file
        write.xlsx(results_df, rv$excel_filename)
      }
      
      # Refresh all data view
      rv$all_data <- read.xlsx(rv$excel_filename)
    })
    
    # Show success message
    error_count <- sum(rv$current_results$provider == "ERROR")
    success_count <- nrow(rv$current_results) - error_count
    
    output$upload_status <- renderUI({
      if (error_count > 0) {
        tags$div(
          class = "alert alert-success",
          tags$strong("Completed! "),
          sprintf("Successfully processed %d receipt(s). %d error(s) occurred. Check the description column for error details.", 
                  success_count, error_count),
          tags$br(),
          tags$small("Files saved with descriptive names in receipts folder")
        )
      } else {
        tags$div(
          class = "alert alert-success",
          tags$strong("✓ Success! "),
          sprintf("Successfully processed all %d receipt(s). Data has been saved to %s with numeric amounts.", 
                  nrow(rv$current_results), rv$excel_filename),
          tags$br(),
          tags$small("Files saved with descriptive names in receipts folder")
        )
      }
    })
  })
  
  # Display current processing results
  output$results_table <- DT::renderDataTable({
    req(rv$current_results)
    DT::datatable(
      rv$current_results,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 'frtip',
        order = list(list(6, 'desc'))  # Sort by timestamp descending
      ),
      rownames = FALSE
    )
  })
  
  # Refresh all data
  observeEvent(input$refresh_data, {
    if (file.exists(rv$excel_filename)) {
      rv$all_data <- read.xlsx(rv$excel_filename)
      showNotification("Data refreshed successfully", type = "message", duration = 2)
    } else {
      showNotification("No data file found", type = "warning", duration = 3)
    }
  })
  
  # Display all processed receipts
  output$all_data_table <- DT::renderDataTable({
    if (file.exists(rv$excel_filename)) {
      if (is.null(rv$all_data)) {
        rv$all_data <- read.xlsx(rv$excel_filename)
      }
      DT::datatable(
        rv$all_data,
        options = list(
          pageLength = 25,
          scrollX = TRUE,
          dom = 'Bfrtip',
          order = list(list(6, 'desc'))  # Sort by timestamp descending
        ),
        rownames = FALSE,
        filter = 'top'  # Add column filters
      )
    }
  })
  
  # Download Excel handler
  output$download_excel <- downloadHandler(
    filename = function() {
      paste0("receipt_data_export_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".xlsx")
    },
    content = function(file) {
      if (file.exists(rv$excel_filename)) {
        file.copy(rv$excel_filename, file)
      }
    }
  )
  
  # Categorize - Show path info
  observeEvent(input$browse_category_folder, {
    showNotification(
      "Enter the full folder path in the text box above. Six category folders will be created automatically inside this path.",
      type = "message",
      duration = 8
    )
  })
  
  # Categorize Tab - Refresh data
  observeEvent(input$refresh_categorize, {
    if (file.exists(rv$excel_filename)) {
      data <- read.xlsx(rv$excel_filename)
      
      # Add category columns if they don't exist
      category_cols <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
      for (col in category_cols) {
        if (!col %in% names(data)) {
          data[[col]] <- 0L
        } else {
          # Ensure they are integers
          data[[col]] <- as.integer(data[[col]])
        }
      }
      
      # Ensure amount is numeric
      if ("amount" %in% names(data)) {
        data$amount <- as.numeric(data$amount)
      }
      
      rv$categorize_data <- data
      calculate_category_totals()
      showNotification("Data refreshed successfully", type = "message", duration = 2)
    } else {
      showNotification("No data file found", type = "warning", duration = 3)
    }
  })
  
  # Function to calculate category totals
  calculate_category_totals <- function() {
    if (!is.null(rv$categorize_data)) {
      # Calculate sum of amounts for each category where value is 1
      totals <- list(
        Labour = sum(rv$categorize_data$amount[rv$categorize_data$Labour == 1], na.rm = TRUE),
        Overheads = sum(rv$categorize_data$amount[rv$categorize_data$Overheads == 1], na.rm = TRUE),
        Materials = sum(rv$categorize_data$amount[rv$categorize_data$Materials == 1], na.rm = TRUE),
        Capital_Usage = sum(rv$categorize_data$amount[rv$categorize_data$Capital_Usage == 1], na.rm = TRUE),
        TS = sum(rv$categorize_data$amount[rv$categorize_data$TS == 1], na.rm = TRUE),
        Contractor = sum(rv$categorize_data$amount[rv$categorize_data$Contractor == 1], na.rm = TRUE)
      )
      rv$category_totals <- totals
    }
  }
  
  # Display category totals UI
  output$category_totals_ui <- renderUI({
    req(rv$category_totals)
    
    tags$div(
      class = "category-totals",
      tags$h4("Category Totals", style = "color: #7ec8e3; margin-bottom: 15px; font-weight: bold;"),
      tags$p("Sum of amounts for each category (only receipts with category = 1):", 
             style = "color: #c7d2fe; margin-bottom: 15px;"),
      lapply(names(rv$category_totals), function(cat) {
        tags$div(
          class = "category-total-item",
          tags$div(class = "category-total-label", gsub("_", " ", cat)),
          tags$div(class = "category-total-amount", 
                   paste0("£", format(rv$category_totals[[cat]], nsmall = 2, big.mark = ",")))
        )
      })
    )
  })
  
  # Display categorize table with editable checkboxes
  output$categorize_table <- DT::renderDataTable({
    # Auto-load data if not already loaded
    if (is.null(rv$categorize_data) && file.exists(rv$excel_filename)) {
      data <- read.xlsx(rv$excel_filename)
      
      # Add category columns if they don't exist
      category_cols <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
      for (col in category_cols) {
        if (!col %in% names(data)) {
          data[[col]] <- 0L
        } else {
          data[[col]] <- as.integer(data[[col]])
        }
      }
      
      # Ensure amount is numeric
      if ("amount" %in% names(data)) {
        data$amount <- as.numeric(data$amount)
      }
      
      rv$categorize_data <- data
      calculate_category_totals()
    }
    
    req(rv$categorize_data)
    
    # Reorder columns for display: move receipt_id, provider, amount, date, description, processed_timestamp to the end
    # New order: filename, Labour, Overheads, Materials, Capital_Usage, TS, Contractor, receipt_id, provider, amount, date, description, processed_timestamp
    display_data <- rv$categorize_data[, c(
      "filename",                    # Column 1
      "Labour",                      # Column 2
      "Overheads",                   # Column 3
      "Materials",                   # Column 4
      "Capital_Usage",               # Column 5
      "TS",                          # Column 6
      "Contractor",                  # Column 7
      "receipt_id",                  # Column 8 (moved to end)
      "provider",                    # Column 9 (moved to end)
      "amount",                      # Column 10 (moved to end)
      "date",                        # Column 11 (moved to end)
      "description",                 # Column 12 (moved to end)
      "processed_timestamp"          # Column 13 (moved to end)
    )]
    
    # Create editable datatable
    # Column 0 (filename) is read-only
    # Columns 1-6 are editable (category checkboxes: 0 or 1)
    # Columns 7-12 are read-only (moved to end)
    DT::datatable(
      display_data,
      editable = list(
        target = 'cell', 
        disable = list(columns = c(0, 7, 8, 9, 10, 11, 12))  # Disable editing for filename and moved columns
      ),
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        columnDefs = list(
          list(targets = 1:6, className = 'dt-center')  # Center the category columns
        ),
        order = list(list(12, 'desc'))  # Sort by processed_timestamp (now column 12)
      ),
      rownames = FALSE
    )
  })
  
  # Handle cell edits in categorize table
  observeEvent(input$categorize_table_cell_edit, {
    info <- input$categorize_table_cell_edit
    row <- info$row
    col <- info$col + 1  # DT uses 0-based indexing, R uses 1-based
    value <- as.integer(info$value)
    
    # In display order, category columns are 2-7 (Labour, Overheads, Materials, Capital_Usage, TS, Contractor)
    # Map back to original data structure where categories are columns 8-13
    if (col >= 2 && col <= 7) {
      # Map display column to original column
      # Display: filename(1), Labour(2), Overheads(3), Materials(4), Capital_Usage(5), TS(6), Contractor(7)
      # Original: receipt_id(1), filename(2), provider(3), amount(4), date(5), description(6), timestamp(7), Labour(8), Overheads(9), Materials(10), Capital_Usage(11), TS(12), Contractor(13)
      original_col <- col + 6  # Labour is display col 2, original col 8 (2+6=8)
      
      # Implement radio button behavior: only one category can be 1
      # Set all categories to 0
      rv$categorize_data[row, 8:13] <- 0L
      # Set selected category to 1 if value is 1
      if (value == 1) {
        rv$categorize_data[row, original_col] <- 1L
      }
      # Recalculate totals
      calculate_category_totals()
    }
  })
  
  # Save categories to Excel
  observeEvent(input$save_categories, {
    req(rv$categorize_data)
    
    # Ensure all category columns are integers (0 or 1)
    category_cols <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
    for (col in category_cols) {
      if (col %in% names(rv$categorize_data)) {
        rv$categorize_data[[col]] <- as.integer(rv$categorize_data[[col]])
      }
    }
    
    # Ensure amount is numeric
    if ("amount" %in% names(rv$categorize_data)) {
      rv$categorize_data$amount <- as.numeric(rv$categorize_data$amount)
    }
    
    # Save to Excel file
    write.xlsx(rv$categorize_data, rv$excel_filename)
    
    # Update all_data reactive value
    rv$all_data <- rv$categorize_data
    
    # Recalculate totals
    calculate_category_totals()
    
    # Show success notification
    showNotification("Categories saved successfully to Excel file!", 
                     type = "message", duration = 3)
  })
  
  # Copy files to category folders
  observeEvent(input$copy_files_to_categories, {
    req(rv$categorize_data)
    
    # Get base path from user input
    base_path <- input$category_base_path
    
    # Create base folder if it doesn't exist
    if (!dir.exists(base_path)) {
      dir.create(base_path, recursive = TRUE)
      showNotification(paste("Created base folder:", base_path), type = "message", duration = 3)
    }
    
    # Define category names
    categories <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
    
    # Create category folders
    for (cat in categories) {
      cat_folder <- file.path(base_path, cat)
      if (!dir.exists(cat_folder)) {
        dir.create(cat_folder, recursive = TRUE)
      }
    }
    
    # Show progress
    withProgress(message = 'Copying files to category folders...', value = 0, {
      copied_count <- 0
      skipped_count <- 0
      
      for (i in 1:nrow(rv$categorize_data)) {
        row <- rv$categorize_data[i, ]
        filename <- row$filename
        source_path <- file.path(rv$receipts_folder, filename)
        
        if (file.exists(source_path)) {
          # Find which category is selected (value = 1)
          category_selected <- FALSE
          for (cat in categories) {
            if (row[[cat]] == 1) {
              dest_path <- file.path(base_path, cat, filename)
              file.copy(source_path, dest_path, overwrite = TRUE)
              copied_count <- copied_count + 1
              category_selected <- TRUE
              break  # Only copy to one category
            }
          }
          if (!category_selected) {
            skipped_count <- skipped_count + 1
          }
        } else {
          skipped_count <- skipped_count + 1
        }
        
        incProgress(1/nrow(rv$categorize_data))
      }
      
      # Show completion message
      showNotification(
        paste0("File copy complete!\n",
               "Copied: ", copied_count, " file(s)\n",
               "Skipped: ", skipped_count, " file(s) (no category or file not found)"),
        type = "message",
        duration = 8
      )
    })
  })
}

# Run the application
shinyApp(ui = ui, server = server)