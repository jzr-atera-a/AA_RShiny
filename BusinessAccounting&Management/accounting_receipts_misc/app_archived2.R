library(shiny)
library(shinydashboard)
library(httr)
library(jsonlite)
library(base64enc)
library(DT)
library(dplyr)

# UI Definition
ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "Receipt Processor"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Settings", tabName = "settings", icon = icon("cog")),
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
      "))
    ),
    
    tabItems(
      # Settings Tab (Now First)
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
              placeholder = "Enter your API key (starts with sk-proj-...)"
            ),
            textInput(
              "receipts_folder",
              "Receipts Storage Folder:",
              value = "receipts"
            ),
            textInput(
              "csv_filename",
              "CSV Output Filename:",
              value = "receipt_data.csv"
            ),
            actionButton("save_settings", "Save Settings", class = "btn-success"),
            hr(),
            verbatimTextOutput("settings_status")
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
            fileInput(
              "receipt_files",
              "Choose Receipt Files (JPG or PDF)",
              multiple = TRUE,
              accept = c(".jpg", ".jpeg", ".pdf"),
              placeholder = "Select up to 5 files"
            ),
            actionButton("process_btn", "Process Receipts", 
                         class = "btn-primary", icon = icon("play")),
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
            actionButton("refresh_data", "Refresh Data", icon = icon("refresh")),
            downloadButton("download_csv", "Download CSV"),
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
            actionButton("save_categories", "Save Categories", 
                         class = "btn-success", icon = icon("save")),
            actionButton("refresh_categorize", "Refresh Data", 
                         class = "btn-info", icon = icon("refresh")),
            hr(),
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
    csv_filename = "receipt_data.csv",
    current_results = NULL,
    all_data = NULL,
    categorize_data = NULL
  )
  
  # Initialize folders and files
  observe({
    if (!dir.exists(rv$receipts_folder)) {
      dir.create(rv$receipts_folder, recursive = TRUE)
    }
    if (!file.exists(rv$csv_filename)) {
      # Create empty CSV with headers
      empty_df <- data.frame(
        receipt_id = character(),
        filename = character(),
        provider = character(),
        amount = character(),
        date = character(),
        description = character(),
        processed_timestamp = character(),
        Labour = logical(),
        Overheads = logical(),
        Materials = logical(),
        Capital_Usage = logical(),
        TS = logical(),
        Contractor = logical(),
        stringsAsFactors = FALSE
      )
      write.csv(empty_df, rv$csv_filename, row.names = FALSE)
    }
  })
  
  # Save settings
  observeEvent(input$save_settings, {
    # Trim whitespace from API key
    rv$api_key <- trimws(input$api_key)
    rv$receipts_folder <- input$receipts_folder
    rv$csv_filename <- input$csv_filename
    
    # Validate API key format for OpenAI
    api_key_valid <- nchar(rv$api_key) > 0 && grepl("^sk-", rv$api_key)
    
    # Create folder if it doesn't exist
    if (!dir.exists(rv$receipts_folder)) {
      dir.create(rv$receipts_folder, recursive = TRUE)
    }
    
    output$settings_status <- renderText({
      paste0("Settings saved successfully!\n",
             "API Key: ", ifelse(nchar(rv$api_key) > 0, 
                                 ifelse(api_key_valid, "Set ✓", "Set (Invalid format - should start with 'sk-')"), 
                                 "Not Set"), "\n",
             "Receipts Folder: ", rv$receipts_folder, "\n",
             "CSV Filename: ", rv$csv_filename)
    })
    
    if (!api_key_valid && nchar(rv$api_key) > 0) {
      showNotification("Warning: API key should start with 'sk-'", type = "warning", duration = 5)
    }
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
  
  # Function to call OpenAI API
  call_openai_api <- function(file_path, filename) {
    if (is.null(rv$api_key) || nchar(rv$api_key) == 0) {
      return(list(error = "API key not set"))
    }
    
    # Encode file
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
                "2. Final amount paid (include currency)\n",
                "3. Date of payment (YYYY-MM-DD format if possible)\n",
                "4. Description of items or services purchased\n\n",
                "Respond ONLY with a valid JSON object in this exact format:\n",
                "{\n",
                '  "provider": "Name of provider/seller",\n',
                '  "amount": "Total amount with currency",\n',
                '  "date": "Date in YYYY-MM-DD format",\n',
                '  "description": "Brief description of items/services"\n',
                "}\n\n",
                "DO NOT include any text outside the JSON object. ",
                "DO NOT use markdown code blocks or backticks."
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
          return(list(error = paste("Failed to parse JSON:", e$message, 
                                    "\nResponse:", response_text)))
        })
      }
    } else if (status_code(response) == 401) {
      return(list(error = "Authentication failed (401). Check your OpenAI API key in Settings tab."))
    } else if (status_code(response) == 429) {
      return(list(error = "Rate limit exceeded (429). Wait a moment and try again."))
    } else if (status_code(response) == 400) {
      error_content <- tryCatch(content(response, "text", encoding = "UTF-8"), error = function(e) "Unknown error")
      return(list(error = paste("Bad request (400):", error_content)))
    }
    
    return(list(error = paste("API error:", status_code(response), "- Check your API key and network connection")))
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
    
    # Show progress
    withProgress(message = 'Processing receipts...', value = 0, {
      
      results_list <- list()
      
      for (i in 1:nrow(input$receipt_files)) {
        file_info <- input$receipt_files[i, ]
        incProgress(1/nrow(input$receipt_files), 
                    detail = paste("Processing", file_info$name))
        
        # Generate unique ID
        receipt_id <- paste0("RCP_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_", i)
        
        # Copy file to receipts folder with ID
        new_filename <- paste0(receipt_id, "_", file_info$name)
        new_filepath <- file.path(rv$receipts_folder, new_filename)
        file.copy(file_info$datapath, new_filepath)
        
        # Call OpenAI API
        result <- call_openai_api(file_info$datapath, file_info$name)
        
        if ("error" %in% names(result)) {
          results_list[[i]] <- data.frame(
            receipt_id = receipt_id,
            filename = new_filename,
            provider = "ERROR",
            amount = "ERROR",
            date = "ERROR",
            description = result$error,
            processed_timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
            Labour = FALSE,
            Overheads = FALSE,
            Materials = FALSE,
            Capital_Usage = FALSE,
            TS = FALSE,
            Contractor = FALSE,
            stringsAsFactors = FALSE
          )
        } else {
          results_list[[i]] <- data.frame(
            receipt_id = receipt_id,
            filename = new_filename,
            provider = ifelse(is.null(result$provider), "N/A", result$provider),
            amount = ifelse(is.null(result$amount), "N/A", result$amount),
            date = ifelse(is.null(result$date), "N/A", result$date),
            description = ifelse(is.null(result$description), "N/A", result$description),
            processed_timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
            Labour = FALSE,
            Overheads = FALSE,
            Materials = FALSE,
            Capital_Usage = FALSE,
            TS = FALSE,
            Contractor = FALSE,
            stringsAsFactors = FALSE
          )
        }
      }
      
      # Combine results
      results_df <- do.call(rbind, results_list)
      rv$current_results <- results_df
      
      # Append to CSV
      if (file.exists(rv$csv_filename)) {
        existing_data <- read.csv(rv$csv_filename, stringsAsFactors = FALSE)
        
        # Add category columns if they don't exist
        category_cols <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
        for (col in category_cols) {
          if (!col %in% names(existing_data)) {
            existing_data[[col]] <- FALSE
          }
        }
        
        combined_data <- rbind(existing_data, results_df)
        write.csv(combined_data, rv$csv_filename, row.names = FALSE)
      } else {
        write.csv(results_df, rv$csv_filename, row.names = FALSE)
      }
      
      # Refresh all data
      rv$all_data <- read.csv(rv$csv_filename, stringsAsFactors = FALSE)
    })
    
    output$upload_status <- renderUI({
      tags$div(
        class = "alert alert-success",
        tags$strong("Success! "),
        sprintf("Processed %d receipt(s). Data saved to %s", 
                nrow(rv$current_results), rv$csv_filename)
      )
    })
  })
  
  # Display current results
  output$results_table <- DT::renderDataTable({
    req(rv$current_results)
    DT::datatable(
      rv$current_results,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 'frtip'
      ),
      rownames = FALSE
    )
  })
  
  # Load all data
  observeEvent(input$refresh_data, {
    if (file.exists(rv$csv_filename)) {
      rv$all_data <- read.csv(rv$csv_filename, stringsAsFactors = FALSE)
    }
  })
  
  # Display all data
  output$all_data_table <- DT::renderDataTable({
    if (file.exists(rv$csv_filename)) {
      if (is.null(rv$all_data)) {
        rv$all_data <- read.csv(rv$csv_filename, stringsAsFactors = FALSE)
      }
      DT::datatable(
        rv$all_data,
        options = list(
          pageLength = 25,
          scrollX = TRUE,
          dom = 'Bfrtip'
        ),
        rownames = FALSE
      )
    }
  })
  
  # Download CSV
  output$download_csv <- downloadHandler(
    filename = function() {
      paste0("receipt_data_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
    },
    content = function(file) {
      if (file.exists(rv$csv_filename)) {
        file.copy(rv$csv_filename, file)
      }
    }
  )
  
  # Categorize Tab - Load data
  observeEvent(input$refresh_categorize, {
    if (file.exists(rv$csv_filename)) {
      data <- read.csv(rv$csv_filename, stringsAsFactors = FALSE)
      
      # Add category columns if they don't exist
      category_cols <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
      for (col in category_cols) {
        if (!col %in% names(data)) {
          data[[col]] <- FALSE
        }
      }
      
      rv$categorize_data <- data
    }
  })
  
  # Display categorize table with editable checkboxes
  output$categorize_table <- DT::renderDataTable({
    # Auto-load data if not already loaded
    if (is.null(rv$categorize_data) && file.exists(rv$csv_filename)) {
      data <- read.csv(rv$csv_filename, stringsAsFactors = FALSE)
      
      # Add category columns if they don't exist
      category_cols <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
      for (col in category_cols) {
        if (!col %in% names(data)) {
          data[[col]] <- FALSE
        }
      }
      
      rv$categorize_data <- data
    }
    
    req(rv$categorize_data)
    
    DT::datatable(
      rv$categorize_data,
      editable = list(target = 'cell', disable = list(columns = c(0:6))),
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        columnDefs = list(
          list(targets = 7:12, className = 'dt-center')
        )
      ),
      rownames = FALSE
    )
  })
  
  # Handle cell edits
  observeEvent(input$categorize_table_cell_edit, {
    info <- input$categorize_table_cell_edit
    rv$categorize_data[info$row, info$col + 1] <- info$value
  })
  
  # Save categories
  observeEvent(input$save_categories, {
    req(rv$categorize_data)
    
    # Convert checkbox values to logical
    category_cols <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
    for (col in category_cols) {
      if (col %in% names(rv$categorize_data)) {
        rv$categorize_data[[col]] <- as.logical(rv$categorize_data[[col]])
      }
    }
    
    # Save to CSV
    write.csv(rv$categorize_data, rv$csv_filename, row.names = FALSE)
    
    # Update all_data
    rv$all_data <- rv$categorize_data
    
    showNotification("Categories saved successfully!", type = "message")
  })
}

# Run the application
shinyApp(ui = ui, server = server)
library(shinydashboard)
library(httr)
library(jsonlite)
library(base64enc)
library(DT)
library(dplyr)

# UI Definition
ui <- dashboardPage(
  dashboardHeader(title = "Receipt Processor"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Upload Receipts", tabName = "upload", icon = icon("upload")),
      menuItem("View Processed Data", tabName = "data", icon = icon("table")),
      menuItem("Categorize Receipts", tabName = "categorize", icon = icon("tags")),
      menuItem("Settings", tabName = "settings", icon = icon("cog"))
    )
  ),
  
  dashboardBody(
    tabItems(
      # Upload Tab
      tabItem(
        tabName = "upload",
        fluidRow(
          box(
            title = "Upload Receipt Images",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            fileInput(
              "receipt_files",
              "Choose Receipt Files (JPG or PDF)",
              multiple = TRUE,
              accept = c(".jpg", ".jpeg", ".pdf"),
              placeholder = "Select up to 5 files"
            ),
            actionButton("process_btn", "Process Receipts", 
                         class = "btn-primary", icon = icon("play")),
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
            actionButton("refresh_data", "Refresh Data", icon = icon("refresh")),
            downloadButton("download_csv", "Download CSV"),
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
            actionButton("save_categories", "Save Categories", 
                         class = "btn-success", icon = icon("save")),
            actionButton("refresh_categorize", "Refresh Data", 
                         class = "btn-info", icon = icon("refresh")),
            hr(),
            DT::dataTableOutput("categorize_table")
          )
        )
      ),
      
      # Settings Tab
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
              "Anthropic API Key:",
              placeholder = "Enter your API key here"
            ),
            textInput(
              "receipts_folder",
              "Receipts Storage Folder:",
              value = "receipts"
            ),
            textInput(
              "csv_filename",
              "CSV Output Filename:",
              value = "receipt_data.csv"
            ),
            actionButton("save_settings", "Save Settings", class = "btn-success"),
            hr(),
            verbatimTextOutput("settings_status")
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
    csv_filename = "receipt_data.csv",
    current_results = NULL,
    all_data = NULL,
    categorize_data = NULL
  )
  
  # Initialize folders and files
  observe({
    if (!dir.exists(rv$receipts_folder)) {
      dir.create(rv$receipts_folder, recursive = TRUE)
    }
    if (!file.exists(rv$csv_filename)) {
      # Create empty CSV with headers
      empty_df <- data.frame(
        receipt_id = character(),
        filename = character(),
        provider = character(),
        amount = character(),
        date = character(),
        description = character(),
        processed_timestamp = character(),
        Labour = logical(),
        Overheads = logical(),
        Materials = logical(),
        Capital_Usage = logical(),
        TS = logical(),
        Contractor = logical(),
        stringsAsFactors = FALSE
      )
      write.csv(empty_df, rv$csv_filename, row.names = FALSE)
    }
  })
  
  # Save settings
  observeEvent(input$save_settings, {
    # Trim whitespace from API key
    rv$api_key <- trimws(input$api_key)
    rv$receipts_folder <- input$receipts_folder
    rv$csv_filename <- input$csv_filename
    
    # Validate API key format
    api_key_valid <- nchar(rv$api_key) > 0 && grepl("^sk-ant-", rv$api_key)
    
    # Create folder if it doesn't exist
    if (!dir.exists(rv$receipts_folder)) {
      dir.create(rv$receipts_folder, recursive = TRUE)
    }
    
    output$settings_status <- renderText({
      paste0("Settings saved successfully!\n",
             "API Key: ", ifelse(nchar(rv$api_key) > 0, 
                                 ifelse(api_key_valid, "Set ✓", "Set (Invalid format - should start with 'sk-ant-')"), 
                                 "Not Set"), "\n",
             "Receipts Folder: ", rv$receipts_folder, "\n",
             "CSV Filename: ", rv$csv_filename)
    })
    
    if (!api_key_valid && nchar(rv$api_key) > 0) {
      showNotification("Warning: API key should start with 'sk-ant-'", type = "warning", duration = 5)
    }
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
  
  # Function to call Claude API
  call_claude_api <- function(file_path, filename) {
    if (is.null(rv$api_key) || nchar(rv$api_key) == 0) {
      return(list(error = "API key not set"))
    }
    
    # Encode file
    base64_data <- encode_file(file_path)
    media_type <- get_media_type(filename)
    
    # Determine content type
    if (media_type == "application/pdf") {
      content_block <- list(
        type = "document",
        source = list(
          type = "base64",
          media_type = media_type,
          data = base64_data
        )
      )
    } else {
      content_block <- list(
        type = "image",
        source = list(
          type = "base64",
          media_type = media_type,
          data = base64_data
        )
      )
    }
    
    # Prepare API request
    api_url <- "https://api.anthropic.com/v1/messages"
    
    body <- list(
      model = "claude-sonnet-4-20250514",
      max_tokens = 1024,
      messages = list(
        list(
          role = "user",
          content = list(
            content_block,
            list(
              type = "text",
              text = paste0(
                "Please analyze this purchase receipt and extract the following information:\n\n",
                "1. Provider/Seller name\n",
                "2. Final amount paid (include currency)\n",
                "3. Date of payment\n",
                "4. Description of items or services purchased\n\n",
                "Respond ONLY with a valid JSON object in this exact format:\n",
                "{\n",
                '  "provider": "Name of provider/seller",\n',
                '  "amount": "Total amount with currency",\n',
                '  "date": "Date in YYYY-MM-DD format if possible",\n',
                '  "description": "Brief description of items/services"\n',
                "}\n\n",
                "DO NOT include any text outside the JSON object. ",
                "DO NOT use markdown code blocks or backticks."
              )
            )
          )
        )
      )
    )
    
    # Make API request
    response <- tryCatch({
      POST(
        url = api_url,
        add_headers(
          `x-api-key` = rv$api_key,
          `anthropic-version` = "2023-06-01",
          `content-type` = "application/json"
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
      if (!is.null(content$content) && length(content$content) > 0) {
        response_text <- content$content[[1]]$text
        
        # Clean up response text (remove markdown formatting if present)
        response_text <- gsub("```json\\s*", "", response_text)
        response_text <- gsub("```\\s*", "", response_text)
        response_text <- trimws(response_text)
        
        # Parse JSON
        tryCatch({
          parsed_data <- fromJSON(response_text)
          return(parsed_data)
        }, error = function(e) {
          return(list(error = paste("Failed to parse JSON:", e$message, 
                                    "\nResponse:", response_text)))
        })
      }
    } else if (status_code(response) == 401) {
      return(list(error = "Authentication failed (401). Check your API key: Go to Settings tab, verify the key starts with 'sk-ant-', remove any extra spaces, and click Save Settings."))
    } else if (status_code(response) == 429) {
      return(list(error = "Rate limit exceeded (429). Wait a moment and try again."))
    } else if (status_code(response) == 400) {
      error_content <- tryCatch(content(response, "text", encoding = "UTF-8"), error = function(e) "Unknown error")
      return(list(error = paste("Bad request (400):", error_content)))
    }
    
    return(list(error = paste("API error:", status_code(response), "- Check your API key and network connection")))
  }
  
  # Process receipts
  observeEvent(input$process_btn, {
    req(input$receipt_files)
    
    # Check API key
    if (is.null(rv$api_key) || nchar(rv$api_key) == 0) {
      showModal(modalDialog(
        title = "API Key Required",
        "Please set your Anthropic API key in the Settings tab first.",
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
    
    # Show progress
    withProgress(message = 'Processing receipts...', value = 0, {
      
      results_list <- list()
      
      for (i in 1:nrow(input$receipt_files)) {
        file_info <- input$receipt_files[i, ]
        incProgress(1/nrow(input$receipt_files), 
                    detail = paste("Processing", file_info$name))
        
        # Generate unique ID
        receipt_id <- paste0("RCP_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_", i)
        
        # Copy file to receipts folder with ID
        new_filename <- paste0(receipt_id, "_", file_info$name)
        new_filepath <- file.path(rv$receipts_folder, new_filename)
        file.copy(file_info$datapath, new_filepath)
        
        # Call Claude API
        result <- call_claude_api(file_info$datapath, file_info$name)
        
        if ("error" %in% names(result)) {
          results_list[[i]] <- data.frame(
            receipt_id = receipt_id,
            filename = new_filename,
            provider = "ERROR",
            amount = "ERROR",
            date = "ERROR",
            description = result$error,
            processed_timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
            Labour = FALSE,
            Overheads = FALSE,
            Materials = FALSE,
            Capital_Usage = FALSE,
            TS = FALSE,
            Contractor = FALSE,
            stringsAsFactors = FALSE
          )
        } else {
          results_list[[i]] <- data.frame(
            receipt_id = receipt_id,
            filename = new_filename,
            provider = ifelse(is.null(result$provider), "N/A", result$provider),
            amount = ifelse(is.null(result$amount), "N/A", result$amount),
            date = ifelse(is.null(result$date), "N/A", result$date),
            description = ifelse(is.null(result$description), "N/A", result$description),
            processed_timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
            Labour = FALSE,
            Overheads = FALSE,
            Materials = FALSE,
            Capital_Usage = FALSE,
            TS = FALSE,
            Contractor = FALSE,
            stringsAsFactors = FALSE
          )
        }
      }
      
      # Combine results
      results_df <- do.call(rbind, results_list)
      rv$current_results <- results_df
      
      # Append to CSV
      if (file.exists(rv$csv_filename)) {
        existing_data <- read.csv(rv$csv_filename, stringsAsFactors = FALSE)
        
        # Add category columns if they don't exist
        category_cols <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
        for (col in category_cols) {
          if (!col %in% names(existing_data)) {
            existing_data[[col]] <- FALSE
          }
        }
        
        combined_data <- rbind(existing_data, results_df)
        write.csv(combined_data, rv$csv_filename, row.names = FALSE)
      } else {
        write.csv(results_df, rv$csv_filename, row.names = FALSE)
      }
      
      # Refresh all data
      rv$all_data <- read.csv(rv$csv_filename, stringsAsFactors = FALSE)
    })
    
    output$upload_status <- renderUI({
      tags$div(
        class = "alert alert-success",
        tags$strong("Success! "),
        sprintf("Processed %d receipt(s). Data saved to %s", 
                nrow(rv$current_results), rv$csv_filename)
      )
    })
  })
  
  # Display current results
  output$results_table <- DT::renderDataTable({
    req(rv$current_results)
    DT::datatable(
      rv$current_results,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 'frtip'
      ),
      rownames = FALSE
    )
  })
  
  # Load all data
  observeEvent(input$refresh_data, {
    if (file.exists(rv$csv_filename)) {
      rv$all_data <- read.csv(rv$csv_filename, stringsAsFactors = FALSE)
    }
  })
  
  # Display all data
  output$all_data_table <- DT::renderDataTable({
    if (file.exists(rv$csv_filename)) {
      if (is.null(rv$all_data)) {
        rv$all_data <- read.csv(rv$csv_filename, stringsAsFactors = FALSE)
      }
      DT::datatable(
        rv$all_data,
        options = list(
          pageLength = 25,
          scrollX = TRUE,
          dom = 'Bfrtip'
        ),
        rownames = FALSE
      )
    }
  })
  
  # Download CSV
  output$download_csv <- downloadHandler(
    filename = function() {
      paste0("receipt_data_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
    },
    content = function(file) {
      if (file.exists(rv$csv_filename)) {
        file.copy(rv$csv_filename, file)
      }
    }
  )
  
  # Categorize Tab - Load data
  observeEvent(input$refresh_categorize, {
    if (file.exists(rv$csv_filename)) {
      data <- read.csv(rv$csv_filename, stringsAsFactors = FALSE)
      
      # Add category columns if they don't exist
      category_cols <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
      for (col in category_cols) {
        if (!col %in% names(data)) {
          data[[col]] <- FALSE
        }
      }
      
      rv$categorize_data <- data
    }
  })
  
  # Display categorize table with editable checkboxes
  output$categorize_table <- DT::renderDataTable({
    # Auto-load data if not already loaded
    if (is.null(rv$categorize_data) && file.exists(rv$csv_filename)) {
      data <- read.csv(rv$csv_filename, stringsAsFactors = FALSE)
      
      # Add category columns if they don't exist
      category_cols <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
      for (col in category_cols) {
        if (!col %in% names(data)) {
          data[[col]] <- FALSE
        }
      }
      
      rv$categorize_data <- data
    }
    
    req(rv$categorize_data)
    
    DT::datatable(
      rv$categorize_data,
      editable = list(target = 'cell', disable = list(columns = c(0:6))),
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        columnDefs = list(
          list(targets = 7:12, className = 'dt-center')
        )
      ),
      rownames = FALSE
    )
  })
  
  # Handle cell edits
  observeEvent(input$categorize_table_cell_edit, {
    info <- input$categorize_table_cell_edit
    rv$categorize_data[info$row, info$col + 1] <- info$value
  })
  
  # Save categories
  observeEvent(input$save_categories, {
    req(rv$categorize_data)
    
    # Convert checkbox values to logical
    category_cols <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
    for (col in category_cols) {
      if (col %in% names(rv$categorize_data)) {
        rv$categorize_data[[col]] <- as.logical(rv$categorize_data[[col]])
      }
    }
    
    # Save to CSV
    write.csv(rv$categorize_data, rv$csv_filename, row.names = FALSE)
    
    # Update all_data
    rv$all_data <- rv$categorize_data
    
    showNotification("Categories saved successfully!", type = "message")
  })
}

# Run the application
shinyApp(ui = ui, server = server)
