library(shiny)
library(shinydashboard)
library(DT)
library(readxl)
library(dplyr)
library(lubridate)
library(openxlsx)
library(httr)
library(jsonlite)

# UI Definition
ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(title = "Timesheet Generator"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("API Settings", tabName = "api_settings", icon = icon("key")),
      menuItem("Timesheet Generator", tabName = "timesheet", icon = icon("calendar"))
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
        
        .selectize-input {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          color: #ffffff !important;
          border: 2px solid #4a90e2 !important;
        }
        
        .selectize-dropdown {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          border: 2px solid #4a90e2 !important;
        }
        
        .selectize-dropdown-content .option {
          color: #e0e7ff !important;
        }
        
        .selectize-dropdown-content .option:hover {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
        }
      "))
    ),
    
    tabItems(
      # API Settings Tab
      tabItem(tabName = "api_settings",
              fluidRow(
                box(
                  title = "OpenAI API Configuration",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  textInput("api_key", "API Key:", 
                            placeholder = "sk-proj-...",
                            width = "100%"),
                  
                  fluidRow(
                    column(6,
                           actionButton("test_connection", "Test Connection", 
                                        icon = icon("plug"),
                                        class = "btn-info")
                    ),
                    column(6,
                           actionButton("save_api_key", "Save Settings", 
                                        icon = icon("save"),
                                        class = "btn-success")
                    )
                  ),
                  
                  br(),
                  uiOutput("api_status")
                )
              )
      ),
      
      # Timesheet Generator Tab
      tabItem(tabName = "timesheet",
              fluidRow(
                # Summary boxes
                infoBoxOutput("total_hours_box", width = 6),
                infoBoxOutput("wp_hours_box", width = 6)
              ),
              
              fluidRow(
                box(
                  title = "Upload Files",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(6,
                           fileInput("travel_file", "Upload Travel Summary (Excel)",
                                     accept = c(".xlsx", ".xls")),
                           actionButton("update_travel", "Update Travel Dates",
                                        icon = icon("plane"),
                                        class = "btn-info")
                    ),
                    column(6,
                           fileInput("gantt_file", "Upload Gantt Chart (Excel)",
                                     accept = c(".xlsx", ".xls")),
                           actionButton("upload_gantt", "Upload Gantt Chart",
                                        icon = icon("chart-gantt"),
                                        class = "btn-info")
                    )
                  ),
                  
                  uiOutput("file_status")
                )
              ),
              
              fluidRow(
                box(
                  title = "Timesheet",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  
                  DTOutput("timesheet_table"),
                  
                  br(),
                  downloadButton("download_timesheet", "Download Timesheet",
                                 class = "btn-success")
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
    api_connected = FALSE,
    timesheet_data = NULL,
    travel_data = NULL,
    gantt_data = NULL,
    work_packages = NULL,
    wp_date_ranges = NULL  # New: store date ranges for each WP
  )
  
  # Test API Connection - FIXED: Changed POST to GET
  observeEvent(input$test_connection, {
    req(input$api_key)
    
    # Trim whitespace from API key
    api_key_trimmed <- trimws(input$api_key)
    
    tryCatch({
      # FIXED: Use GET instead of POST for /v1/models endpoint
      response <- GET(
        "https://api.openai.com/v1/models",
        add_headers(
          "Authorization" = paste("Bearer", api_key_trimmed),
          "Content-Type" = "application/json"
        ),
        timeout(30)  # Add timeout to prevent hanging
      )
      
      status <- status_code(response)
      
      if (status == 200) {
        rv$api_connected <- TRUE
        rv$api_key <- api_key_trimmed
        output$api_status <- renderUI({
          div(class = "alert alert-success",
              icon("check-circle"), " API Connection Successful!")
        })
      } else if (status == 401) {
        rv$api_connected <- FALSE
        output$api_status <- renderUI({
          div(class = "alert alert-danger",
              icon("times-circle"), " API Connection Failed: Invalid API key. Please check your API key.")
        })
      } else if (status == 429) {
        rv$api_connected <- FALSE
        output$api_status <- renderUI({
          div(class = "alert alert-danger",
              icon("times-circle"), " API Connection Failed: Rate limit exceeded. Please try again later.")
        })
      } else {
        rv$api_connected <- FALSE
        response_content <- content(response, "text", encoding = "UTF-8")
        output$api_status <- renderUI({
          div(class = "alert alert-danger",
              icon("times-circle"), 
              sprintf(" API Connection Failed (Status %d). Response: %s", status, substr(response_content, 1, 200)))
        })
      }
    }, error = function(e) {
      rv$api_connected <- FALSE
      output$api_status <- renderUI({
        div(class = "alert alert-danger",
            icon("times-circle"), " Connection Error: ", e$message,
            br(),
            tags$small("Please check your internet connection and try again."))
      })
    })
  })
  
  # Save API Key
  observeEvent(input$save_api_key, {
    req(input$api_key)
    rv$api_key <- trimws(input$api_key)
    
    output$api_status <- renderUI({
      div(class = "alert alert-success",
          icon("check"), " API Key Saved Successfully!")
    })
  })
  
  # Upload and process Gantt Chart
  observeEvent(input$upload_gantt, {
    req(input$gantt_file)
    
    tryCatch({
      # Read the Gantt chart without headers (raw data)
      df <- read_excel(input$gantt_file$datapath, col_names = FALSE)
      
      # The structure is:
      # Row 1: Quarter headers (Q1, Q2, etc.)
      # Row 2: Column headers (ID, Dependencies, TITLE, OWNER, months...)
      # Row 3+: Actual data
      # Column A (index 1 in R): ID (e.g., "3.1", "4.4")
      # Column C (index 3 in R): TITLE (the description)
      
      # Skip first 2 rows (quarters and headers)
      if (nrow(df) > 2) {
        df <- df[3:nrow(df), ]
      }
      
      # Determine active date range from travel data
      if (!is.null(rv$travel_data)) {
        start_month <- month(min(rv$travel_data$Date))
        end_month <- month(max(rv$travel_data$Date))
      } else {
        # Default to Q2: Aug (8), Sep (9), Oct (10)
        start_month <- 8
        end_month <- 10
      }
      
      # Column mapping for months (after skipping header rows):
      # The month columns start from column 5 (index 5 in R)
      # Apr=5, May=6, Jun=7, Jul=8, Aug=9, Sep=10, Oct=11, Nov=12, Dec=13, Jan=14, Feb=15, Mar=16, Apr=17
      # For Q2 2025 (Aug-Oct), we check columns 9, 10, 11
      month_to_col <- list(
        '4' = 5, '5' = 6, '6' = 7, '7' = 8, 
        '8' = 9, '9' = 10, '10' = 11, '11' = 12, '12' = 13
      )
      
      active_cols <- c()
      for (m in start_month:end_month) {
        col_idx <- month_to_col[[as.character(m)]]
        if (!is.null(col_idx)) {
          active_cols <- c(active_cols, col_idx)
        }
      }
      
      # Extract work packages with activity in the date range
      wp_list <- list()
      wp_date_ranges <- list()
      
      for (i in 1:nrow(df)) {
        # Column 1 = ID (e.g., "3.1", "4.4"), Column 3 = TITLE
        id_val <- df[i, 1]
        title_val <- df[i, 3]
        
        # Convert to character and clean
        id_val <- as.character(id_val)
        title_val <- as.character(title_val)
        
        # Remove asterisks and trim whitespace
        id_val <- gsub("\\*", "", id_val)
        id_val <- trimws(id_val)
        title_val <- gsub("\\*", "", title_val)
        title_val <- trimws(title_val)
        
        # Check if this is a valid work package ID (format: X.Y where X and Y are numbers)
        if (!is.na(id_val) && id_val != "" && grepl("^[0-9]+\\.[0-9]+$", id_val)) {
          # Check if any cells in active columns have colored fill
          has_activity <- FALSE
          active_months <- c()
          
          for (col_idx in active_cols) {
            if (col_idx <= ncol(df)) {
              cell_value <- df[i, col_idx]
              
              # In the Gantt chart, colored cells may be NA, empty string, or have content
              # We need to check the actual cell fill color in Excel
              # For now, we'll consider any non-empty cell as activity
              if (!is.na(cell_value) && cell_value != "" && cell_value != 0) {
                has_activity <- TRUE
                
                # Determine which month this column represents
                month_num <- which(sapply(month_to_col, function(x) x == col_idx))
                if (length(month_num) > 0) {
                  active_months <- c(active_months, as.numeric(names(month_to_col)[month_num]))
                }
              }
            }
          }
          
          # If no activity detected by cell content, include WP 3.x and above for Q2
          if (!has_activity) {
            wp_num <- as.numeric(substr(id_val, 1, 1))
            if (wp_num >= 3) {
              has_activity <- TRUE
              active_months <- c(start_month:end_month)
            }
          }
          
          if (has_activity) {
            # Store WP with its title from column 3
            wp_list[[id_val]] <- list(
              id = id_val,
              title = if(!is.na(title_val) && title_val != "" && title_val != "NA") {
                title_val
              } else {
                paste("Work Package", id_val)
              }
            )
            
            # Store date range for this WP
            if (length(active_months) > 0) {
              wp_date_ranges[[id_val]] <- list(
                start_month = min(active_months),
                end_month = max(active_months)
              )
            }
          }
        }
      }
      
      # If no work packages found (maybe all cells are colored but empty), 
      # include all WPs for the period
      if (length(wp_list) == 0) {
        for (i in 1:nrow(df)) {
          id_val <- df[i, 1]
          title_val <- df[i, 3]
          
          # Convert to character and clean
          id_val <- as.character(id_val)
          title_val <- as.character(title_val)
          
          # Remove asterisks and trim whitespace
          id_val <- gsub("\\*", "", id_val)
          id_val <- trimws(id_val)
          title_val <- gsub("\\*", "", title_val)
          title_val <- trimws(title_val)
          
          if (!is.na(id_val) && id_val != "" && grepl("^[0-9]+\\.[0-9]+$", id_val)) {
            # For Q2, include WPs 3.x, 4.x, 5.x, 6.x (not 1.x, 2.x)
            wp_num <- as.numeric(substr(id_val, 1, 1))
            if (wp_num >= 3) {
              wp_list[[id_val]] <- list(
                id = id_val,
                title = if(!is.na(title_val) && title_val != "" && title_val != "NA") {
                  title_val
                } else {
                  paste("Work Package", id_val)
                }
              )
              
              # Default to full period
              wp_date_ranges[[id_val]] <- list(
                start_month = start_month,
                end_month = end_month
              )
            }
          }
        }
      }
      
      rv$work_packages <- wp_list
      rv$wp_date_ranges <- wp_date_ranges
      rv$gantt_data <- df
      
      wp_ids <- paste(names(wp_list), collapse = ", ")
      
      output$file_status <- renderUI({
        div(class = "alert alert-success",
            icon("check"), 
            sprintf(" Gantt Chart loaded: %d active work packages for period", length(wp_list)),
            br(),
            tags$small(sprintf("Active WPs: %s", wp_ids)))
      })
      
      # DO NOT regenerate timesheet - preserve existing data
      # The user will manually edit the WorkPackage column
      
    }, error = function(e) {
      output$file_status <- renderUI({
        div(class = "alert alert-danger",
            icon("times-circle"), " Error loading Gantt Chart: ", e$message)
      })
    })
  })
  
  # Generate initial timesheet
  generate_timesheet <- function() {
    if (is.null(rv$travel_data)) {
      # If no travel data, use Q2 2025 as default
      start_date <- as.Date("2025-08-01")
      end_date <- as.Date("2025-10-31")
    } else {
      # Use travel data date range
      start_date <- floor_date(min(rv$travel_data$Date), "month")
      end_date <- ceiling_date(max(rv$travel_data$Date), "month") - days(1)
    }
    
    # Generate all dates
    all_dates <- seq(start_date, end_date, by = "day")
    
    # Create base dataframe
    df <- data.frame(
      Date = all_dates,
      DoW = weekdays(all_dates, abbreviate = FALSE),
      Task = "Technical",
      WorkPackage = ifelse(!is.null(rv$work_packages), names(rv$work_packages)[1], "4.4"),
      StartTime = ifelse(weekdays(all_dates) == "Sunday", "", "09:00"),
      EndTime = ifelse(weekdays(all_dates) == "Sunday", "", "17:00"),
      Hours = ifelse(weekdays(all_dates) == "Sunday", 0, 8),
      Description = "",
      stringsAsFactors = FALSE
    )
    
    rv$timesheet_data <- df
  }
  
  # Update with travel dates
  observeEvent(input$update_travel, {
    req(input$travel_file)
    
    tryCatch({
      travel_df <- read_excel(input$travel_file$datapath)
      
      # Convert Date column to Date type
      travel_df$Date <- as.Date(travel_df$Date)
      rv$travel_data <- travel_df
      
      # Generate timesheet if it doesn't exist
      if (is.null(rv$timesheet_data)) {
        generate_timesheet()
      }
      
      # Update travel dates
      for (i in 1:nrow(travel_df)) {
        travel_date <- travel_df$Date[i]
        location <- travel_df$`Location(s)`[i]
        
        # Find matching row in timesheet
        idx <- which(rv$timesheet_data$Date == travel_date)
        
        if (length(idx) > 0) {
          rv$timesheet_data$Task[idx] <- "Work Travel"
          rv$timesheet_data$Description[idx] <- paste("Relevant work travel in", location)
        }
      }
      
      output$file_status <- renderUI({
        div(class = "alert alert-success",
            icon("check"), sprintf(" Travel dates updated: %d dates", nrow(travel_df)))
      })
      
    }, error = function(e) {
      output$file_status <- renderUI({
        div(class = "alert alert-danger",
            icon("times-circle"), " Error loading travel file: ", e$message)
      })
    })
  })
  
  # Initialize timesheet on app start
  observe({
    if (is.null(rv$timesheet_data)) {
      generate_timesheet()
    }
  })
  
  # Helper function to get available WPs for a specific date
  get_available_wps_for_date <- function(date_val) {
    if (is.null(rv$work_packages) || is.null(rv$wp_date_ranges)) {
      # Default Q2-active work packages
      return(c("3.1", "3.2", "3.3", "3.4", 
               "4.1", "4.2", "4.3", "4.4", "4.5", "4.6", "4.7",
               "5.1", "5.2", "5.3", "5.4", "5.5", "5.6", "5.7",
               "6.1", "6.2", "6.3", "6.4"))
    }
    
    # Get month of the date
    date_month <- month(date_val)
    
    # Filter WPs that are active in this month
    available_wps <- c()
    for (wp_id in names(rv$wp_date_ranges)) {
      wp_range <- rv$wp_date_ranges[[wp_id]]
      if (date_month >= wp_range$start_month && date_month <= wp_range$end_month) {
        available_wps <- c(available_wps, wp_id)
      }
    }
    
    return(available_wps)
  }
  
  # Render editable timesheet table
  output$timesheet_table <- renderDT({
    req(rv$timesheet_data)
    
    datatable(
      rv$timesheet_data,
      editable = list(
        target = 'cell',
        disable = list(columns = c(0, 1)) # Date and DoW not editable
      ),
      options = list(
        pageLength = 31,
        scrollX = TRUE,
        columnDefs = list(
          list(className = 'dt-center', targets = 0:7)
        )
      ),
      selection = 'none',
      rownames = FALSE
    ) %>%
      formatStyle(
        'DoW',
        target = 'row',
        backgroundColor = styleEqual('Sunday', '#764ba2')
      )
  })
  
  # Handle cell edits
  observeEvent(input$timesheet_table_cell_edit, {
    info <- input$timesheet_table_cell_edit
    
    row <- info$row
    col <- info$col + 1  # R is 1-indexed
    value <- info$value
    
    # Get the column name
    col_name <- names(rv$timesheet_data)[col]
    
    # Update the cell value
    rv$timesheet_data[row, col] <- value
    
    # Special handling for WorkPackage column
    if (col_name == "WorkPackage") {
      # Auto-populate Description with WP title from Gantt chart
      if (!is.null(rv$work_packages) && value %in% names(rv$work_packages)) {
        wp_title <- rv$work_packages[[value]]$title
        rv$timesheet_data$Description[row] <- wp_title
        
        # Show notification to confirm
        showNotification(
          paste0("Description updated to: ", wp_title),
          type = "message",
          duration = 3
        )
      } else {
        # WP not found in loaded Gantt
        showNotification(
          paste0("Work Package ", value, " not found in Gantt chart. Please upload Gantt chart or check WP ID."),
          type = "warning",
          duration = 5
        )
      }
    }
    
    # If Hours column is edited, update EndTime
    if (col_name == "Hours") {
      start_time <- rv$timesheet_data$StartTime[row]
      if (start_time != "" && !is.na(value) && value > 0) {
        start_hour <- as.numeric(substr(start_time, 1, 2))
        end_hour <- start_hour + as.numeric(value)
        rv$timesheet_data$EndTime[row] <- sprintf("%02d:00", end_hour)
      }
    }
  })
  
  # Calculate total hours by month
  output$total_hours_box <- renderInfoBox({
    req(rv$timesheet_data)
    
    df <- rv$timesheet_data
    df$Month <- format(df$Date, "%B %Y")
    
    monthly_hours <- df %>%
      group_by(Month) %>%
      summarise(TotalHours = sum(as.numeric(Hours), na.rm = TRUE)) %>%
      arrange(Month)
    
    total <- sum(as.numeric(df$Hours), na.rm = TRUE)
    
    details <- paste(
      sapply(1:nrow(monthly_hours), function(i) {
        paste(monthly_hours$Month[i], ":", monthly_hours$TotalHours[i], "hrs")
      }),
      collapse = " | "
    )
    
    infoBox(
      "Total Hours",
      total,
      details,
      icon = icon("clock"),
      color = "purple"
    )
  })
  
  # Calculate total hours by work package
  output$wp_hours_box <- renderInfoBox({
    req(rv$timesheet_data)
    
    df <- rv$timesheet_data
    
    wp_hours <- df %>%
      group_by(WorkPackage) %>%
      summarise(TotalHours = sum(as.numeric(Hours), na.rm = TRUE)) %>%
      arrange(WorkPackage)
    
    top_wp <- wp_hours %>% slice_max(TotalHours, n = 1)
    
    details <- paste(
      "Top: WP", top_wp$WorkPackage[1], "-", top_wp$TotalHours[1], "hrs"
    )
    
    infoBox(
      "Work Packages",
      nrow(wp_hours),
      details,
      icon = icon("tasks"),
      color = "blue"
    )
  })
  
  # Download timesheet
  output$download_timesheet <- downloadHandler(
    filename = function() {
      paste0("Timesheet_Q2_", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      write.xlsx(rv$timesheet_data, file)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)